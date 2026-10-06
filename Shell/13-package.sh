# Description for specified package
function pkgdesc {
	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<'EOF'
Usage: pkgdesc <package_name>

Return the description of specified package.

Arguments:
  package_name    Name of the package whose build.sh should be used.

Options:
  -h, --help      Display this help message.

Examples:
  pkgdesc zlib
		Return zlib's description.
  pkgdesc vim
		Return vim's description.
EOF
		return 0
	fi
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]; then
		local build_sh="$LFP/$pkgname/build.sh"
	fi
	
	[[ -f $build_sh ]] || {
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
    }
	cat $LFP/$pkgname/build.sh | grep "^description=" | cut -d '"' -f 2
}

function pkgdown {
	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<'EOF'
Usage: pkgdown <package_name> [number]

Run the specified number of source download lines for specified package.

Arguments:
  package_name    Name of the package whose build.sh should be used.
  number          Number of download lines to include. Defaults to 1.
                  1 = run the first download line.
                  2 = run the first and second download line.
                  3 = run up to the third download line.
                  And so forth.

A download line is either a call to download_src or a call to a function
whose name ends in _download.

Options:
  -h, --help      Display this help message.

Examples:
  pkgdown zlib
      Run the first download line of zlib. 

  pkgdown zlib 2
      Run the first to second download lines of zlib.

  pkgdown zlib 3
      Run the first to third download lines of zlib.
EOF
		return 0
	fi

	local pkgname=$1
	local no=${2:-1}
	local build_sh="$LFP/$pkgname/build.sh"

	[[ -f "$build_sh" ]] || {
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
	}

	(
		pushd "$LFP/$pkgname" >/dev/null || exit 1

		source <(awk -v n="$no" '
			{
				print

				if ($0 ~ /^[[:space:]]*(download_src|[[:alnum:]_-]+_download)([[:space:]]|$)/) {
					count++
					if (count >= n)
						exit
				}
			}
		' "$build_sh")

		popd >/dev/null
	)
}

function pkgurl {
	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<'EOF'
Usage: pkgurl <package_name>

Return the homepage of specified package.

Arguments:
  package_name    Name of the package whose build.sh should be used.

Options:
  -h, --help      Display this help message.

Examples:
  pkgurl zlib
		Return zlib's homepage.
  pkgurl vim
		Return vim's homepage.
EOF
		return 0
	fi
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]; then
		local build_sh="$LFP/$pkgname/build.sh"
	fi
	
	[[ -f $build_sh ]] || {
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
    }
	(
		source <(
			sed -n '1,/^homepage=/p' "$build_sh"
		)
		printf '%s\n' "$homepage"
	)
}

# Print the installed version of specified package. 
function pkgver {
	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<'EOF'
Usage: pkgver <package_name>

Return the current installed version of the specified package.

Arguments:
  package_name    Name of the package whose installed version should be 
				  returned.

Options:
  -h, --help      Display this help message.

Examples:
  pkgver zlib
		Return zlib's current installed version.
  pkgver vim
		Return vim's current installed version.
EOF
		return 0
	fi
	find /var/lib/{book,custom}-packages -type f -name "$1" -exec sh -c '
    for file; do
        head -n1 "$file"
    done
' sh {} +
}

# Print the upstream version of specified package based on its `version=` line.
function upver {
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]; then
		local build_sh="$LFP/$pkgname/build.sh"
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

function pkgdep {
	local pkgname=$1
	grep -r "depends=" $LFP/$pkgname/build.sh | cut -d '(' -f 2 \
	       | cut -d ')' -f 1
}

function pkgrevdep {
	if [[ $1 =~ ^[a-z0-9_-]+$ && -f $LFP/$1/build.sh ]]; then
		local pkgname=$1
	else
		echo "pkgrevdep takes a package name and returns the packages that " \
		     "depend upon it based on the contents of their build.sh file."
		return 1
	fi
	grep --include="build.sh" -R "depends=.*$pkgname" $LFP \
		| sed "s|$LFP/||g" | cut -d '/' -f 1 | sort
}

function add_deps_progress {
	local pkg=$(ps ax | grep add_deps | grep -v "grep\|sed" | sed 's|.*add_deps.py\s||g')
	if [[ -z $pkg ]]; then
		echo "add_deps is not running, exiting."
		return 1
	fi
	local completed=$(find $LFP -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
		| sort -f | awk -v dir="$pkg" 'tolower($0) < tolower(dir)' | wc -l)
	local perc=$(Reval "round($completed/$(no_pkgs)*100, digits=2)")
	echo "Add deps loop is up to $pkg and is hence ${perc}% done."
}