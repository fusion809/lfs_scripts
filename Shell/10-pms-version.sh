function pkgver {
	find /var/lib/{book,custom}-packages -type f -name "*$1*" -exec sh -c '
    for file; do
        head -n1 "$file"
    done
' sh {} +
}

function upver {
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]; then
		local build_sh="$LFP/$pkgname/build.sh"
	else
		local build_sh="$LFP/uninstalled/$pkgname/build.sh"
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