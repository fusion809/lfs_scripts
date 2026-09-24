
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
	source ~/lfs-scripts/Shell/19-miscellaneous.sh
	update-grub
}
