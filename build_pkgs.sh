#!/bin/zsh
source $HOME/.zshrc
function empty_bdur_pkgs {
	comm -23 \
    <(find /var/lib/custom-packages -maxdepth 1 -type f -printf '%f\n' | sort) \
    <(find ~/build_duration -maxdepth 1 -type f -printf '%f\n' | sort) | grep -v "libdvdread\|expect"
}
function upd_pkgs {
	cat ~/logs/updates.log | grep "\[UPDATE\]" | cut -d ' ' -f 1
}
function upd_pkgs_err_filt {
	cat ~/logs/updates.log |
        grep '\[UPDATE\]' |
        cut -d ' ' -f 1 |
        grep -v -F -x -f <(grep -rl '^\[ERROR\]' ~/build_logs/ | cut -d '/' -f 5)
}
function pkg_list {
	printf '%s\n' "$@" | uniq | sort
}
function build_log_pkgs {
	while read -r pkg
	do
		autobuild "$pkg" -f | tee ~/build_logs/$pkg
	done <<< $pkgs
}

while :;
do
	if ! ps ax | grep '\.lfs_autobuild.sh' | grep -v "grep '\.lfs_autobuild.sh'" &> /dev/null; then
		pkgs=$(pkg_list "$(bfail)" "$(empty_bdur_pkgs)" "$(upd_pkgs)")
		build_log_pkgs "$pkgs"
		pkgs=$(upd_pkgs_err_filt)
		build_log_pkgs "$pkgs"
		rm_old_share
		rm_old_docs
		break;
	fi
done
