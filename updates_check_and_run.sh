#!/bin/bash
pkgver () {
	if [[ -n $2 ]]
	then
		find /var/lib/{book,custom}-packages -type f -name "$1" -exec sh -c '
            lines=$1
            shift
            for file; do
                head -n "$lines" "$file" | tail -n 1
            done
        ' sh "$2" {} + | sort -V | tail -n 1
	else
		find /var/lib/{book,custom}-packages -type f -name "$1" -exec sh -c '
            for file; do
                head -n 1 "$file"
            done
        ' sh {} + | sort -V | tail -n 1
	fi
}
upver () {
	local pkgname=$1
	if [[ -f $LFP/$pkgname/build.sh ]]
	then
		local build_sh="$LFP/$pkgname/build.sh"
	else
		printf 'No build.sh found for %s\n' "$pkgname" >&2
		return 1
	fi
	(
		source <(
			sed -n '1,/^version=/p' "$build_sh"
		)
		printf '%s\n' "$version"
	)
}

source $HOME/lfs_packaging/shared-funcs.sh
set -u
logfile="$HOME/logs/updates.log"
logdir="$HOME/logs"

mkdir -p "$logdir"

timestamp=$(date '+%Y%m%d_%H%M%S')
runlog="$logdir/updatec.log.$timestamp"

exec > >(tee -a "$runlog") 2>&1

echo "===== Update check started: $(date '+%F %T %Z') ====="
echo "Run log: $runlog"

# Prevent overlapping instances of this service script.
exec 9>"$logdir/updates_check_and_run.lock"
if ! flock -n 9; then
    echo "Another updates_check_and_run.sh instance is running; skipping."
    exit 0
fi

if [[ ! -f $logfile ]]; then
    echo "ERROR: Update log not found: $logfile"
    exit 1
fi

# Identify packages requiring updates.
mapfile -t pkgs_updates < <(
    awk '/\[UPDATE\]|\[FILES MISSING\]/ { print $1 }' "$logfile"
)

pkgs=()
if (( ${#pkgs_updates[@]} > 0 )); then
	for i in ${pkgs_updates[@]}
	do
		if [[ $(upver $i) != $(pkgver $i) ]]; then
			pkgs+=("$i")
		fi
	done
	if (( ${#pkgs[@]} == 0 )); then
		echo "No packages need updating."
		exit 0
	fi
else
    echo "No packages need updating."
    exit 0
fi

printf 'Packages needing attention: %s\n' "${pkgs[*]}"

# Check whether the autobuild script is already running.
autobuild_running=false

for proc in /proc/[0-9]*; do
    [[ -r $proc/cmdline ]] || continue
    pid=${proc##*/}

    # Exclude this script and its parent processes.
    [[ $pid == "$$" || $pid == "$PPID" ]] && continue

    cmdline=$(tr '\0' '\n' < "$proc/cmdline" 2>/dev/null || :)

    if grep -Fxq -- "$HOME/.lfs_autobuild.sh" <<< "$cmdline" ||
       grep -Fxq -- "$HOME/lfs-scripts/.lfs_autobuild.sh" <<< "$cmdline"; then
        autobuild_running=true
        echo "Autobuild process found: PID $pid"
        break
    fi
done

if [[ $autobuild_running == true ]]; then
    echo ".lfs_autobuild.sh is running; skipping updatec."
    exit 0
fi

# Prevent concurrent updatec runs that honour this lock.
exec 8>"$logdir/updatec.lock"
if ! flock -n 8; then
    echo "Another updater holds updatec.lock; skipping."
    exit 0
fi

# Check for an updatec command already running, including manually
# launched instances that do not use the lock above.
while IFS= read -r pid; do
    [[ -r /proc/$pid/cmdline ]] || continue

    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || :)

    if [[ $cmdline == *"zsh -ic updatec"* ]]; then
        echo "Existing updatec process found (PID $pid); skipping."
        exit 0
    fi
done < <(pgrep -x zsh || true)

echo "===== Starting updatec: $(date '+%F %T %Z') ====="

if zsh -ic 'updatec'; then
    status=0
    echo "===== updatec completed successfully ====="
else
    status=$?
    echo "===== ERROR: updatec exited with status $status ====="
fi

echo "Finished: $(date '+%F %T %Z')"
echo "Exit status: $status"

exit "$status"

