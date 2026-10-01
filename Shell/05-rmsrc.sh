function rm_lfp_src {
	cdlfp
	for tarball in $(find . -name '*.tar*'); do
    		dir=${tarball%.tar.*}   # removes .tar.xz, .tar.gz, .tar.bz2, etc.
    		if [[ -d "$dir" ]]; then
			sudo rm -rf "$dir"
			sudo rm -rf "$tarball"
		else
			sudo rm -rf "$tarball"
    		fi
	done
	cd -
}

function rmSrc {
	cdlfp
	find . -mindepth 2 -maxdepth 2 -type d \
    ! -exec test -d '{}/.git' ';' -print
	find . -name "*.tar*" -delete
}

function rm_book_src {
	sudo rm -rf /sources/*
	mkdir /sources/archives -p
}

function rm_src {
	rm_book_src
	rm_lfp_src
}