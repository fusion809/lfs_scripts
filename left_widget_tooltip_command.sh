#!/bin/bash
echo "$(~/lfs-scripts/os_version.sh)"
echo "󰏗 $(~/lfs-scripts/packages_no_long.sh)"
echo "$(~/lfs-scripts/autobuild-time-elapsed.sh)"
echo "$(~/lfs-scripts/last_autobuild.sh | grep -v "running")"
