#!/bin/bash
pkgs=($(grep -E '\[UPDATE\]|\[FILES MISSING\]' "$HOME/logs/updates.log" |
        cut -d ' ' -f 1))
if ((${#pkgs[@]})) && ! (ps ax | grep "updatec\|autobuild" | grep -v "grep \"updatec\|autobuild\"" &> /dev/null); then
	zsh -ic "updatec"
fi
