#!/bin/bash
jobs=$(ps ax | grep "autobuild\.sh" | grep -v grep)
if [[ -n "$jobs" ]]; then
	echo "autobuild job(s):"
else
	exit 1
fi
source $HOME/lfs-scripts/Shell/00-env.sh
source $HOME/lfs-scripts/Shell/01-cd.sh
source $HOME/lfs-scripts/Shell/02-pms.sh
# Load build_time func
while IFS= read -r job; do
	start=$(ps -p "$(echo $job | awk '{print $1}')" -o lstart=)
	elapsed=$(( $(date +%s) - $(date -d "$start" +%s) ))
	pkg=$(echo $job | sed 's/.*.sh //g' | sed 's/-f//g' | sed 's/\s//g')
	perc=$(R -q -e "round($elapsed/$(med_build_time_sec $pkg)*100)" | grep "^\[1\]" | cut -d ' ' -f 2)
	printf '%s time elapsed: %02d:%02d:%02d (%s%% completed)' \
    	$pkg \
    	$((elapsed / 3600)) \
    	$(((elapsed % 3600) / 60)) \
    	$((elapsed % 60)) \
	$perc
done <<< $jobs
