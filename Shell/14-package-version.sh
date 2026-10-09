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

function verchecks {
	for i in $LFP/*/build.sh
	do
		local pkg=$(echo $i | sed "s|$LFP/||g" | cut -d '/' -f 1)
		printf "pkg=$pkg"
		local arch_ver=$(aver $pkg | sed 's/\.r.*//g')
		local mon_ver=$(uver $pkg 2>/dev/null)
		local art_ver=$(artver $pkg | sed 's/\.r.*//g')
		local nix_ver=$(nixver "$pkg" | sed 's/-unstable.*//g')
		local inst_ver=$(pkgver $pkg)
		local inst_ver_fx=$(echo $inst_ver | sed -E 's/-([0-9])/\.\1/g')
		local vat_ver=$(vatver $pkg)
		local newest=$(newest_ver $arch_ver $art_ver $mon_ver $nix_ver $vat_ver \
			$inst_ver_fx)
		if [[ "$inst_ver_fx" != "$newest" ]] && [[ -f $CP/$pkg ]] &&
			! { [[ "$pkg" == "bash" || "$pkg" == "readline" ]] &&
			[[ "$newest" =~ ^${inst_ver_fx//./\\.}\.[0-9]+$ ]]; }; then
			printf " %s, %s" "$newest" "$inst_ver"
		fi
		printf "\n"
	done
}
