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
	#pkgs=$(cat $HOME/logs/updates.log | grep -E '\[UPDATE\]|\[FILES MISSING\]' | cut -d ' ' -f 1 | tr '\n' ' ' | sed 's/\s*$//g')
	#if echo $pkgs | grep -E "[a-z]"	&> /dev/null; then
#		autobuild $pkgs -f
#	fi
#	qupdate () {
    pkgs=($(grep -E '\[UPDATE\]|\[FILES MISSING\]' "$HOME/logs/updates.log" |
        cut -d ' ' -f 1))
printf '<%s>\n' "${pkgs[@]}"
    if ((${#pkgs[@]})); then
        autobuild "${pkgs[@]}" -f
    fi
}

function qupdatec {
	qupdate
	rm_old_libs
	rm_old_docs
	rm_old_share
	rm_old_kerns
}
