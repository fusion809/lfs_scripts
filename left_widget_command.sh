#!/bin/zsh
source $HOME/.zshrc
boot_dur=$(boot_time)
if [[ -z "$boot_dur" ]]; then
	boot_dur=$(systemd-analyze 2>/dev/null | awk -F"= " "/Startup finished in/ {print \$2}")
fi
system_age=$(~/lfs-scripts/system-age.sh)
echo " $boot_dur $system_age"
