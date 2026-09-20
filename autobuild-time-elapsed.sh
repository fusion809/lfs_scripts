#!/bin/bash
jobs=$(ps ax | grep "autobuild\.sh" | grep -v grep)
if [[ -n "$jobs" ]]; then
	echo "autobuild job(s):"
else
	exit 1
fi
# Load build_time func
while IFS= read -r job; do
	start=$(ps -p "$(echo $job | awk '{print $1}')" -o lstart=)
	elapsed=$(( $(date +%s) - $(date -d "$start" +%s) ))
	pkg=$(echo $job | sed 's/.*.sh //g' | sed 's/-f//g' | sed 's/\s//g')
	DURATION_LOG=$HOME/build_duration/$pkg
	avg_duration_rnd=0
	if [[ -s "$DURATION_LOG" ]]; then
		avg_duration_rnd=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f\n", sum/count; else print 0}' "$DURATION_LOG")
		avg_duration_rnd=${avg_duration_rnd:-0}
	fi
	perc=$(R -q -e "$elapsed/$avg_duration_rnd" | grep "^\[1\]" | cut -d ' ' -f 2)
	printf '%s time elapsed: %02d:%02d:%02d (%s percent completed)' \
    	$pkg \
    	$((elapsed / 3600)) \
    	$(((elapsed % 3600) / 60)) \
    	$((elapsed % 60)) \
	$perc
done <<< $jobs
