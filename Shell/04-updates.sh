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

function updatec_after {
	while :;
	do
		if ! ps ax | grep "autobuild\.sh" | grep -v grep &> /dev/null; then
			updatec
			break
		fi
	done
}
