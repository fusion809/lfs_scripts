function rm_lfp_src {
	cdlfp
	for tarball in $(find . -type f \( \
    -name '*.tar.*' -o \
    -name '*.tgz' -o \
    -name '*.deb' -o \
    -name '*.rpm' \
    \)); do
		if echo $tarball | grep ".tar" &> /dev/null; then
    			dir=${tarball%.tar.*}   # removes .tar.xz, .tar.gz, .tar.bz2, etc.
		elif echo $tarball | grep tgz &> /dev/null; then
			dir=${tarball%.tgz}
		else
			dir=${tarball%.*}
		fi
    		if [[ -d "$dir" ]]; then
			if (( $(pgrep -fc '\.lfs_autobuild\.sh|ninja|cmake|make|configure|autogen|autoreconf') > 1 )); then
				sudo rm -rf "$dir"
			fi
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
