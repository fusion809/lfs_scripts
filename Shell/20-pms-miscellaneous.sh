function add_deps_progress {
	local pkg=$(ps ax | grep add_deps | grep -v "grep\|sed" | sed 's|.*add_deps.py\s||g')
	if [[ -z $pkg ]]; then
		echo "add_deps is not running, exiting."
		return 1
	fi
	local completed=$(find $LFP -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
		| sort -f | awk -v dir="$pkg" 'tolower($0) < tolower(dir)' | wc -l)
	local perc=$(Reval "round($completed/$(no_pkgs)*100, digits=2)")
	echo "Add deps loop is up to $pkg and is hence ${perc}% done."
}