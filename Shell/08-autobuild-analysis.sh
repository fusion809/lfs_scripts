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

# Get the currently building package for a given autobuild PID
function current_pkg_from_pid {
    local pid="$1"

    # 1. Check for dedicated state file if available
    if [[ -f "/tmp/autobuild_${pid}_current" ]]; then
        awk '{print $1}' "/tmp/autobuild_${pid}_current"
        return
    elif [[ -f "/tmp/autobuild_current" ]]; then
        awk '{print $1}' "/tmp/autobuild_current"
        return
    fi

    # 2. Check for active /tmp/build_start_timestamp_*
    local ts_file
    ts_file=$(ls -t /tmp/build_start_timestamp_* 2>/dev/null | head -n 1)
    if [[ -n "$ts_file" ]]; then
        echo "${ts_file#/tmp/build_start_timestamp_}"
        return
    fi

    # 3. Check child processes (e.g. tee writing to build_logs/<pkg>)
    local child_pkg
    child_pkg=$(pgrep -P "$pid" -a 2>/dev/null | grep -oE 'build_logs/[^ ]+' | head -n 1 | sed 's|build_logs/||')
    if [[ -n "$child_pkg" ]]; then
        echo "$child_pkg"
        return
    fi

    # 4. Check cwd of the autobuild process or its child (for custom packages)
    local cwd
    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null)
    if [[ "$cwd" == *"/lfs_packaging/"* ]]; then
        basename "$cwd"
        return
    fi

    echo "unknown"
}

# Get elapsed time for the current package build (not the entire script)
function btime_pkg_elapsed {
    local pid="$1"
    local pkg="$2"

    # 1. State file start time
    if [[ -f "/tmp/autobuild_${pid}_current" ]]; then
        local start_ts
        start_ts=$(awk '{print $2}' "/tmp/autobuild_${pid}_current")
        if [[ -n "$start_ts" ]]; then
            echo $(( $(date +%s) - start_ts ))
            return
        fi
    fi

    # 2. Timestamp file mtime
    if [[ -f "/tmp/build_start_timestamp_${pkg}" ]]; then
        local file_ts
        file_ts=$(stat -c %Y "/tmp/build_start_timestamp_${pkg}" 2>/dev/null)
        if [[ -n "$file_ts" ]]; then
            echo $(( $(date +%s) - file_ts ))
            return
        fi
    fi

    # Fallback: total process elapsed time
    local start
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
        local pid
        pid=$(echo "$job" | awk '{print $1}')

        local pkg
        pkg=$(current_pkg_from_pid "$pid")
        local elapsed
        elapsed=$(btime_pkg_elapsed "$pid" "$pkg")
        local med
        med=$(med_build_time_sec "$pkg")

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
