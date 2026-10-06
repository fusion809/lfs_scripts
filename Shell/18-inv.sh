function packages_push {
	if ! [[ -n "$0" ]]; then
		push "$(git-changed-list): file list"
	else
		push "$(git-changed-list): $0"
	fi
}

function list_fileless {
	if ! ( [[ $(pwd) == "/var/lib/book-packages" ]] || [[ $(pwd) == "/var/lib/custom-packages" ]] ) ; then
		cdbp
	fi	
	grep -L '/' *
}

function perc_fileless {
	perc=$(Reval "(0-$(grep -L '/' * | wc -l)/$(ls | wc -l))*100")
	echo "$perc% of packages have file lists"
}

function inv {
	find /var/lib/{book,custom}-packages -type f -name "*$1*" -exec sh -c '
    for file; do
        tail -n +2 "$file"
    done
' sh {} +
}

remove_duplicate_book_packages() {
    for file in /var/lib/book-packages/*; do
        [[ -f "$file" ]] || continue

        name=${file##*/}

        if [[ -f "/var/lib/custom-packages/$name" ]] && [[ -d "$HOME/lfs_packaging/$name" ]]; then
            sudo rm -vf "$file"
        fi
    done
}

alias rm_dup_bp=remove_duplicate_book_packages
