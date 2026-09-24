
function count_pkgs_left {
	local pkg=$(ps ax | grep autobuild.sh | grep -v "grep.*autobuild.sh" | sed 's/.*sh //g' | sed 's/-f//g')
	count=0
    for f in $CP/*(N); do
        name=${f:t}
        if [[ "$name" > $pkg && ! -e ~/build_duration/$name ]]; then
            ((count++))
        fi
    done
    echo $count
}

function find_deps {
    python3 -c '
import os, sys, subprocess, re

targets = sys.argv[1:]
if not targets:
    print("Usage: who_needs_lib <library_name_or_pattern> [lib2 ...]")
    sys.exit(1)

# 1. Map registered files (canonical realpaths) to package names
file_to_pkg = {}
for pdir in ["/var/lib/book-packages", "/var/lib/custom-packages"]:
    if not os.path.isdir(pdir): continue
    for pf in os.listdir(pdir):
        fpath = os.path.join(pdir, pf)
        try:
            with open(fpath, "r", errors="ignore") as f:
                for line in f.read().splitlines()[1:]:
                    line = line.strip()
                    if line:
                        file_to_pkg[os.path.realpath(line)] = pf
                        file_to_pkg[line] = pf
        except: pass

# 2. Gather candidates with followlinks=True (/opt/*/{lib,bin}, /usr, /lib)
candidates = set(file_to_pkg.keys())
for root_dir in ["/opt", "/usr/bin", "/usr/lib", "/usr/libexec", "/lib"]:
    if not os.path.isdir(root_dir): continue
    for root, dirs, files in os.walk(root_dir, followlinks=True):
        for fname in files:
            candidates.add(os.path.join(root, fname))

matched_pkgs = set()
untracked_files = []
scanned_realpaths = set()

# Compile target regexes
target_patterns = [re.compile(re.escape(t).replace(r"\*", ".*"), re.IGNORECASE) for t in targets]
fast_bytes = [t.encode("utf-8") for t in targets]

for filepath in sorted(candidates):
    try:
        rpath = os.path.realpath(filepath)
        if rpath in scanned_realpaths:
            continue
        scanned_realpaths.add(rpath)
        if not os.path.isfile(rpath):
            continue

        with open(rpath, "rb") as f:
            if f.read(4) != b"\x7fELF":
                continue
            f.seek(0)
            content = f.read(4 * 1024 * 1024)
            if not any(fb.split(b".so")[0] in content for fb in fast_bytes):
                continue

            out = subprocess.check_output(["readelf", "-d", rpath], stderr=subprocess.DEVNULL).decode("utf-8", errors="ignore")
            for line in out.splitlines():
                if "(NEEDED)" in line:
                    for pat in target_patterns:
                        if pat.search(line):
                            soname = line.split("[")[-1].split("]")[0]
                            pkg = file_to_pkg.get(filepath) or file_to_pkg.get(rpath)
                            if not pkg:
                                if "/opt/rustc" in filepath or "/opt/rustc" in rpath: pkg = "rustc"
                                elif "/opt/qt" in filepath or "/opt/qt" in rpath: pkg = "qt6"
                                else: pkg = "UNTRACKED"
                            print(f"[{pkg}] {filepath} -> {soname}")
                            if pkg != "UNTRACKED":
                                matched_pkgs.add(pkg)
                            else:
                                untracked_files.append(filepath)
                            break
    except:
        pass

print("\n========================================")
print(f"Packages needing {targets}:")
print(" ".join(sorted(matched_pkgs)))
if untracked_files:
    print("\nUntracked files:")
    for uf in untracked_files:
        print(f"  - {uf}")
print("========================================")
' "$@"
}

function missing_search {
    local pattern="${1:-not found}"

    for i in /usr/lib/* /usr/bin/*; do
        [[ -e "$i" ]] || continue

        if file -L "$i" | grep -q 'ELF'; then
            if ldd "$i" 2>/dev/null | grep -q "$pattern"; then
                echo "$i"
            fi
        fi
    done
}

function missing_search_fast {
    local pattern="${1:-not found}"
    find /usr/lib /usr/bin /opt/qt6/bin /opt/qt6/lib /opt/rustc/bin /opt/rustc/lib /opt/texlive/2025/bin /opt/texlive/2025/lib -type f -print0 |
    while IFS= read -r -d '' f; do
        ldd "$f" 2>/dev/null | grep -q "$pattern" && printf '%s\n' "$f"
    done
}

function rm_dup_pkgs {
	for file in /var/lib/book-packages/*; do
        [[ -f "$file" ]] || continue
        if [[ -f "/var/lib/custom-packages/$(basename "$file")" ]]; then
            rm "$file"
        fi
    done
}

function slack_download {
	unset DOWNLOAD_x86_64
	source *.info
	if [[ -n $DOWNLOAD_x86_64 ]]; then
		echo "x86_64!"
		URL=$(cat *.info | grep DOWNLOAD_x86_64 | cut -d '"' -f 2)
	else
		echo "Not x86_64!"
		URL=$(cat *.info | grep DOWNLOAD | cut -d '"' -f 2)
	fi
	echo "URL=$URL"
	wget -c $URL
}

function strip_system {
	sudo su -c 'save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.34
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zstd $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-debug /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.45.1.so
               libsframe.so.2.0.0
               libhistory.so.8.3
               libncursesw.so.6.6
               libm.so.6
               libreadline.so.8.3
               libz.so.1.3.1
               libzstd.so.1.5.7
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-debug /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-debug /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-debug $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib'
}
