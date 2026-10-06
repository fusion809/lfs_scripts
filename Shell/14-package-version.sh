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
