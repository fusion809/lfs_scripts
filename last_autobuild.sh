latest=$(find "$HOME/build_logs" -type f -printf '%T@ %p\n' 2>/dev/null |
	sort -nr |
        head -n 1)
if pgrep -f '[.]lfs_autobuild\.sh' > /dev/null; then
	echo "Autobuild is running."
elif [[ -n $latest ]]; then
	last_updated=${latest%% *}
	filepath=${latest#* }
        stamp=$(date -d "@${last_updated%.*}" '+%I:%M:%S%p %d/%m/%y')
	pkg=${filepath##*/}
        pkg=${pkg%.*}

        echo "Autobuild last ran at $stamp on $pkg."
else
        echo "No files found in $HOME/build_logs"
        return 1
fi
