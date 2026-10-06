# Print the installed version of specified package. 
function pkgver {
	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<'EOF'
Usage: pkgver <package_name> [<no>]

Return the current installed version of the specified package.

Arguments:
  package_name    Name of the package whose installed version should be 
				  returned.
  no              Number of the package inventory line who contains the
                  version of interest. Default: 1.

Options:
  -h, --help      Display this help message.

Examples:
  pkgver zlib
		Return zlib's current installed version.
  pkgver vim
		Return vim's current installed version.
  pkgver qhull 2
        Return the second version line in qhull.
EOF
		return 0
	fi
	if [[ -n "$2" ]]; then
        local no=$2
        head -n $no $CP/$1 | tail -n 1
    else
        head -n 1 $CP/$1
    fi
}

# Print the upstream version of specified package based on its `version=` line.
function upver {
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]; then
		local build_sh="$LFP/$pkgname/build.sh"
    else
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
    fi

	(
		source <(
			sed -n '1,/^version=/p' "$build_sh"
		)
		printf '%s\n' "$version"
	)
}
