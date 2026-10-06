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