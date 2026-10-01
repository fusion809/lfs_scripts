function quick_updates {
	upds=$(cat $HOME/logs/updates.log \
		| grep "\[UPDATE\]" \
		| sed 's/\[UPDATE\]//g')
	if echo "$upds" | grep -E "[a-zA-Z]" &> /dev/null; then
		echo "$upds"
	else
		echo "No updates available."
	fi
}
alias qupdates=quick_updates

function qupdate {
    pkgs=($(grep -E '\[UPDATE\]|\[FILES MISSING\]' "$HOME/logs/updates.log" |
        cut -d ' ' -f 1))
printf '<%s>\n' "${pkgs[@]}"
    if ((${#pkgs[@]})); then
        autobuild "${pkgs[@]}" -f
    fi
}

alias quick_update=qupdate

function qupdatec {
	qupdate
	rm_old_libs
	rm_old_docs
	rm_old_share
	rm_old_kerns
}

alias quick_updatec=qupdatec