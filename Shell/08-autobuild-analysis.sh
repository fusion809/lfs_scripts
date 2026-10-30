function btime_elapsed {
    local start=$(ps -p "$(echo $1 | awk '{print $1}')" -o lstart=)
    local elapsed=$(( $(date +%s) - $(date -d "$start" +%s) ))
    echo "$elapsed"
}

function pkg_from_job {
    echo $1 | sed 's/.*.sh //g' | sed 's/-f//g' | sed 's/\s//g'
}

function R_eval {
    R -q -e "$1" | grep "^\[1\]" | cut -d ' ' -f 2
}

# Return true if a build process for $pkg is live
function _pkg_build_running {
    local pkg="$1"
    # Custom-package path: sudo bash /tmp/remote_script_${pkg}.sh
    pgrep -f "remote_script_${pkg}" > /dev/null 2>&1 && return 0
    # Book-package path: bash autobuild.sh ... ${pkg}
    pgrep -fa "" 2>/dev/null | grep -qE "(lfs_autobuild|autobuild)[^/[:space:]]*[[:space:]].*\b${pkg}\b" && return 0
    return 1
}

function current_pkg_from_pid {
    local pid="$1"
    local marker="/tmp/autobuild_${pid}_current"
    local child_pid child_pkg cwd cmd pkg
    local -a descendants=()
    local -a queue=("$pid")
    local index=1

    # Prefer the PID-specific marker.
    if [[ -f "$marker" ]]; then
        pkg=$(awk 'NR == 1 {print $1}' "$marker")
        if [[ -n "$pkg" ]]; then
            printf '%s\n' "$pkg"
            return 0
        fi
    fi

    # Build a list of all descendants, not just direct children.
    while (( index <= ${#queue[@]} )); do
        pid="${queue[$index]}"
        (( index++ ))

        while IFS= read -r child_pid; do
            [[ -z "$child_pid" ]] && continue
            descendants+=("$child_pid")
            queue+=("$child_pid")
        done < <(pgrep -P "$pid" 2>/dev/null)
    done

    # Look for a build-log path in the process tree.
    for child_pid in "${descendants[@]}"; do
        cmd=$(tr '\0' ' ' < "/proc/$child_pid/cmdline" 2>/dev/null)
        child_pkg=$(printf '%s\n' "$cmd" |
            grep -oE 'build_logs/[^ /]+' |
            head -n 1 |
            sed 's|build_logs/||')

        if [[ -n "$child_pkg" ]]; then
            printf '%s\n' "$child_pkg"
            return 0
        fi
    done

    # Look for a package-specific working directory in the process tree.
    for child_pid in "${descendants[@]}" "$pid"; do
        cwd=$(readlink -f "/proc/$child_pid/cwd" 2>/dev/null)

        if [[ "$cwd" == *"/lfs_packaging/"* ]]; then
            pkg="${cwd#*/lfs_packaging/}"
            pkg="${pkg%%/*}"

            if [[ -n "$pkg" && "$pkg" != "." ]]; then
                printf '%s\n' "$pkg"
                return 0
            fi
        fi
    done

    # Fall back to the package argument of this autobuild invocation.
    cmd=$(tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null)

    for pkg in povray inkscape gimp vectorcraft-bin openexr; do
        if [[ " $cmd " == *" $pkg "* ]]; then
            printf '%s\n' "$pkg"
            return 0
        fi
    done

    printf '%s\n' "unknown"
}

function btime_pkg_elapsed {
    local pid="$1"
    local pkg="$2"
    local start_ts file_ts start

    # Prefer the PID-specific start timestamp.
    if [[ -f "/tmp/autobuild_${pid}_current" ]]; then
        start_ts=$(awk 'NR == 1 {print $2}' "/tmp/autobuild_${pid}_current")

        if [[ "$start_ts" =~ ^[0-9]+$ ]]; then
            echo $(( $(date +%s) - start_ts ))
            return
        fi
    fi

    # Fall back to the package timestamp.
    if [[ -n "$pkg" && -f "/tmp/build_start_timestamp_${pkg}" ]]; then
        file_ts=$(stat -c %Y "/tmp/build_start_timestamp_${pkg}" 2>/dev/null)

        if [[ "$file_ts" =~ ^[0-9]+$ ]]; then
            echo $(( $(date +%s) - file_ts ))
            return
        fi
    fi

    # Last resort: time since the autobuild process started.
    start=$(ps -p "$pid" -o lstart= 2>/dev/null)

    if [[ -n "$start" ]]; then
        echo $(( $(date +%s) - $(date -d "$start" +%s) ))
    else
        echo 0
    fi
}
# Elapsed time of current autobuild job
function cbtime {
    local jobs
    jobs=$(ps -eo pid,cmd | grep "[a]utobuild\.sh")
    if [[ -z "$jobs" ]]; then
        echo "No autobuild job(s) running."
        return 1
    fi

    echo "autobuild job(s):"
    while IFS= read -r job; do
        [[ -z "$job" ]] && continue
        local pid=$(echo "$job" | awk '{print $1}')
	local pkg=$(current_pkg_from_pid "$pid" 2>/dev/null)
        local elapsed=$(btime_pkg_elapsed "$pid" "$pkg" 2>/dev/null)
        local med=$(med_build_time_sec "$pkg" 2>/dev/null)

        local perc="N/A"
        if [[ -n "$med" && "$med" -gt 0 ]]; then
            # Using awk avoids spawning R for a simple calculation
            perc=$(awk -v e="$elapsed" -v m="$med" 'BEGIN { printf "%.0f", (e / m) * 100 }')
            perc="${perc}%"
        fi

        printf '%s (PID %s) time elapsed: %02d:%02d:%02d (%s completed)\n' \
            "$pkg" \
            "$pid" \
            $((elapsed / 3600)) \
            $(((elapsed % 3600) / 60)) \
            $((elapsed % 60)) \
            "$perc"
    done <<< "$jobs"
}

function autobuild_log {
	if ps ax | grep autobuild | grep -v "grep \"autobuild\"" &> /dev/null; then
		tail -f /tmp/lfs-autobuild.log
	else
		echo "No autobuild process running. Below is the last 10 lines of lfs-autobuild.log"
		tail -n 10 /tmp/lfs-autobuild.log
	fi
}


function last_build {
	$HOME/lfs-scripts/last_autobuild.sh
}

function cbtime_sec {
    local jobs
    jobs=$(ps -eo pid,cmd | grep "[a]utobuild\.sh")

    if [[ -z "$jobs" ]]; then
        echo "No autobuild job(s) running."
        return 1
    fi

    local total_elapsed=0

    while IFS= read -r job; do
        [[ -z "$job" ]] && continue

        local pid pkg elapsed
        pid=$(awk '{print $1}' <<< "$job")
        pkg=$(current_pkg_from_pid "$pid")
        elapsed=$(btime_pkg_elapsed "$pid" "$pkg") || continue
        total_elapsed=$(R_eval "$total_elapsed + $elapsed")
    done <<< "$jobs"

    printf '%s\n' "$total_elapsed"
}

function update_time_left {
    local -a pkgs
    pkgs=("${(@f)$(grep '\[UPDATE\]' "$HOME/logs/updates.log" | cut -d ' ' -f 1)}")

    echo "pkgs=${(j: :)pkgs}"

    local update_time
    update_time=$(med_build_time_sec "${pkgs[@]}")
    echo "update_time=$update_time"

    local build_time
    build_time=$(cbtime_sec)
    local pkg=$(current_pkg_from_pid $(pgrep -f '\.lfs_autobuild\.sh'))
    if (( $(med_build_time_sec $pkg) < $build_time )); then
	    echo "Build time has exceeded median build time."
	    build_time=$(med_build_time_sec $pkg)
    fi
    echo "build_time=$build_time"

    local rem_update_time
    rem_update_time=$(R_eval "$update_time - $build_time")
    echo "Expected remaining build time=$(readable_time $rem_update_time)"
}
