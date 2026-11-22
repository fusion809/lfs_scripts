source $HOME/.lfs_scripts/21-lfs.sh

# lfs_autobuild: run the host's latest lfs-autobuild.sh (synced to ~/.lfs_autobuild.sh by the host)
function autobuild {
    bash ~/.lfs_autobuild.sh "$@"
}
source ~/.lfs_scripts/lfs-vm-bootstrap.sh 2>/dev/null

function updatec_log {
	tail -f $HOME/logs/updatec.log.$(ps ax | grep "updatec.log*" | grep -v "grep --color" | sed 's|.*/home/fusion809||g' | sed 's/.*log.//g' | sort | tail -n 1)
}

function autobuild_log {
	local logs=$(ps ax | grep "autobuild.*log" | grep -v "grep --color=auto" | sed 's|.*/||g' | sort | uniq)
	local no=$(echo $logs | wc -l)
	if [[ -z "$1" ]]; then
		local log=$(echo $logs | tail -n 1)
	else
		local log=$(echo $logs | head -n $2 | tail -n 1)
	fi
	echo "Number of autobuild logs=$no"
	tail -f $HOME/logs/$log
}
