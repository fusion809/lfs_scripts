source $HOME/.lfs_scripts/21-lfs.sh

function instLfp {
	if [[ -d $HOME/lfs_packaging/$1 ]]; then
		cdlp "$1"
		./build.sh
	fi
}

function rm_lfp_src {
	cdlfp
	for tarball in $(find . -name '*.tar*'); do
    		dir=${tarball%.tar.*}   # removes .tar.xz, .tar.gz, .tar.bz2, etc.
    		if [[ -d "$dir" ]]; then
			sudo rm -rf "$dir"
			sudo rm -rf "$tarball"
		else
			sudo rm -rf "$tarball"
    		fi
	done
	cd -
}

function download {
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

function pkgver {
	find /var/lib/{book,custom}-packages -type f -name "*$1*" -exec sh -c '
    for file; do
        head -n1 "$file"
    done
' sh {} +
}

function rmSrc {
	cdlfp
	find . -mindepth 2 -maxdepth 2 -type d \
    ! -exec test -d '{}/.git' ';' -print
	find . -name "*.tar*" -delete
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

# lfs_autobuild: run the host's latest lfs-autobuild.sh (synced to ~/.lfs_autobuild.sh by the host)
autobuild() {
    bash ~/.lfs_autobuild.sh "$@"
}

missing_search() {
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

missing_search_fast() {
    local pattern="${1:-not found}"
    find /usr/lib /usr/bin /opt/qt6/bin /opt/qt6/lib /opt/rustc/bin /opt/rustc/lib /opt/texlive/2025/bin /opt/texlive/2025/lib -type f -print0 |
    while IFS= read -r -d '' f; do
        ldd "$f" 2>/dev/null | grep -q "$pattern" && printf '%s\n' "$f"
    done
}

function version {
	if [[ -n "$1" ]]; then
		pushd $LFS/"$1"
	fi
	eval "$(grep '^version=' build.sh)"
	echo "$version"
	if [[ -n "$1" ]]; then
		popd
	fi
}

function check_version {
	if [[ -n "$1" ]]; then
		name="$1"
		pushd $LFS/"$1"
	else
		name=$(pwd | sed 's|.*/||g')
	fi
	eval "$(grep '^version=' build.sh)"
	inst_version="$(cat /var/lib/lfs-custom-packages/$name)"
	if [[ "$inst_version" != "$version" ]]; then
		echo "Installed version = $inst_version"
		echo "Upstream version  = $version"
	fi
	if [[ -n "$1" ]]; then
		popd
	fi
}

source ~/.lfs_scripts/lfs-vm-bootstrap.sh 2>/dev/null

alias preserved-rebuild=rm_old_libs_gpt
alias preserved_rebuild=rm_old_libs_gpt
function rm_old_kerns {
	current=$(uname -r)
	echo "Deleting kernels older than $current..."
	find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V |
	while read -r ver; do
	    if [[ "$ver" == "$current" ]]; then
        	break
	    fi
	    sudo rm -rf "/lib/modules/$ver"
	    echo "/lib/modules/$ver was deleted"
	done
	find /boot -maxdepth 1 -type f \
    \( -name "vmlinuz-*" -o \
       -name "initramfs-*" -o \
       -name "System.map-*" -o \
       -name "config-*" \) |
	while read -r file; do
		if echo $file | grep "vmlinuz" &> /dev/null; then
			ver=${file##*/vmlinuz-}
		else
			ver=${file##*-}
			ver=${ver%.img}
		fi

	    if [[ "$(printf '%s\n%s\n' "$ver" "$current" | sort -V | head -n1)" == *"$ver"* &&
	          "$ver" != "$current" ]]; then
	        sudo rm -f "$file"
	        echo "$file was deleted."
	    fi
	done
	source ~/lfs-scripts/Shell/10-miscellaneous.sh
	update-grub

}

function rm_book_src {
	sudo rm -rf /sources/*
	mkdir /sources/archives -p
}

function rm_src {
	rm_book_src
	rm_lfp_src
}

function updc {
	update "$@"
	local broken_pkgs=$(find /var/lib/book-packages /var/lib/custom-packages -maxdepth 1 -type f ! -name ".*" 2>/dev/null | grep -vE "/(COMMIT_EDITMSG|HEAD|config|description|ORIG_HEAD)$" | while read -r f; do (head -n 1 "$f" | grep -q "^BUILD_FAILED$" || [ $(wc -l < "$f") -le 1 ]) && basename "$f"; done | tr -d '\r')
	if [ -z "$broken_pkgs" ]; then
		rm_old_docs
		rm_old_kerns
		rm_old_libs
		rm_old_share
		rm_src
		lfs_commit
	else
		echo "Build failures or missing inventories detected. Skipping cleanup."
	fi
}

alias updatec=updc

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

function rm_dup_pkgs {
	for file in /var/lib/book-packages/*; do
        [[ -f "$file" ]] || continue
        if [[ -f "/var/lib/custom-packages/$(basename "$file")" ]]; then
            rm "$file"
        fi
    done
}

function firefox_inv {
	sudo bash -c '
PKG="firefox"
VERSION=$(ls /sources/firefox* -ld | sed "s|.*/sources/||g" | cut -d "-" -f 2 | sed "s/\.source//g")
INV="/var/lib/book-packages/${PKG}"

echo "$VERSION" > "$INV"
find /usr/bin/firefox /usr/lib/firefox /usr/share/applications/firefox.desktop /usr/share/pixmaps/firefox.png -type f -o -type l 2>/dev/null | sort -u >> "$INV"
chmod 755 "$INV"
'
}

function upver {
	local pkgname=$1
	if [[ -f $HOME/lfs_packaging/$pkgname/build.sh ]]; then
		local build_sh="$HOME/lfs_packaging/$pkgname/build.sh"
	else
		local build_sh="$HOME/lfs_packaging/uninstalled/$pkgname/build.sh"
	fi
	
	[[ -f $build_sh ]] || {
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
        }

	(
		source <(
			sed -n '1,/^version=/p' "$build_sh"
		)
		printf '%s\n' "$version"
	)
}

function updatec_after {
	while :;
	do
		if ! ps ax | grep "autobuild\.sh" | grep -v grep &> /dev/null; then
			updatec
			break
		fi
	done
}

function build_time {
	local DURATION_LOG=$HOME/build_duration/$1
	local avg_duration_rnd=0
	if [[ -s "$DURATION_LOG" ]]; then
		avg_duration_rnd=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f\n", sum/count; else print 0}' "$DURATION_LOG")
		avg_duration_rnd=${avg_duration_rnd:-0}
	fi
	local hours=$(($avg_duration_rnd/3600))
	local mins=$((($avg_duration_rnd % 3600) / 60))
	local secs=$(($avg_duration_rnd % 60))
	echo "$1 took ${hours}h ${mins}m ${secs}s to build"
}

function bfail {
	grep -rl '^\[ERROR\]' ~/build_logs | cut -d '/' -f 5 | sort
}

function failmsg {
	if [[ -n $2 ]]; then
		grep -r '^\[ERROR\]' ~/build_logs/$1 -B $2
	else
		grep -r '^\[ERROR\]' ~/build_logs/$1 -B 20
	fi
}

function shortbd {
	grep -rl '^[0-9]$' ~/build_duration
}

function count_pkgs_left {
	local pkg=$(ps ax | grep autobuild.sh | grep -v "grep.*autobuild.sh" | sed 's/.*sh //g' | sed 's/-f//g')
	count=0
for f in /var/lib/custom-packages/*(N); do
    name=${f:t}
    if [[ "$name" > $pkg && ! -e ~/build_duration/$name ]]; then
        ((count++))
    fi
done
echo $count
}

function ls_pkgs_by_bdur {
	for pkg in /var/lib/custom-packages/*
do
    pkg=${pkg##*/}
    log="$HOME/build_duration/$pkg"

    [[ -s "$log" ]] || continue

    avg=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f", sum/count; else print 0}' "$log")

    hours=$((avg / 3600))
    mins=$(((avg % 3600) / 60))
    secs=$((avg % 60))

    printf '%d\t%s\t%dh %dm %ds\n' \
        "$avg" "$pkg" "$hours" "$mins" "$secs"
done |
sort -k1,1nr |
cut -f2- |
column -t -s $'\t' | less
}

function quick_updates {
	pkgs=$(cat ~/logs/updates.log | grep "\[UPDATE\]" | cut -d ' ' -f 1)
	if echo "$pkgs" | grep -E "[a-zA-Z]" &> /dev/null; then
		echo "$pkgs"
	else
		echo "No updates available."
	fi
}
alias qupdates=quick_updates
