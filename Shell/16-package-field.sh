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