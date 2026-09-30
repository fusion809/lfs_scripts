# Average-based build_time
function avg_build_time {
	local DURATION_LOG=$HOME/build_duration/$1
	local avg_duration_rnd=0
	if [[ -s "$DURATION_LOG" ]]; then
		avg_duration_rnd=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f\n", sum/count; else print 0}' "$DURATION_LOG")
		avg_duration_rnd=${avg_duration_rnd:-0}
	fi
	local hours=$(($avg_duration_rnd/3600))
	local mins=$((($avg_duration_rnd % 3600) / 60))
	local secs=$(($avg_duration_rnd % 60))
	echo "$1: ${hours}h${mins}m${secs}s"
}

function med_build_time_sec {
    local DURATION_LOG=$HOME/build_duration/$1
    local median_duration_rnd=0
    if [[ -s "$DURATION_LOG" ]]; then
        median_duration_rnd=$(sort -n "$DURATION_LOG" |
            awk '{
                a[NR] = $1
            }
            END {
                if (NR == 0) print 0
                else if (NR % 2) print a[(NR + 1) / 2]
                else print (a[NR / 2] + a[NR / 2 + 1]) / 2
            }')
        median_duration_rnd=$(printf "%.0f" "$median_duration_rnd")
    fi
    echo $median_duration_rnd
}

alias mbts=med_build_time_sec
alias mbtimesec=med_build_time_sec

function med_build_time {
    local median_duration=$(med_build_time_sec "$1")
    local hours=$(($median_duration/3600))
    local mins=$((($median_duration % 3600) / 60))
    local secs=$(($median_duration % 60))
    printf "%s: %02d:%02d:%02d\n" "$1" "$hours" "$mins" "$secs"
}

alias mbt=med_build_time
alias mbtime=med_build_time


function ls_pkgs_by_bdur {
	for pkg in /var/lib/custom-packages/*
    do
        pkg=${pkg##*/}
        log="$HOME/build_duration/$pkg"

        [[ -s "$log" ]] || continue

        avg=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f", sum/count; else print 0}' "$log")

        hours=$((avg / 3600))
        mins=$(((avg % 3600) / 60))
        secs=$((avg % 60))

        printf '%d\t%s\t%dh %dm %ds\n' \
            "$avg" "$pkg" "$hours" "$mins" "$secs"
    done |
sort -k1,1nr |
cut -f2- |
column -t -s $'\t' | less
}

function ls_pkgs_size_by_bd {
    find "$LFP" -mindepth 2 -maxdepth 2 -name build.sh -printf '%h\n' |
    while read -r dir; do
        pkg=${dir##*/}
        [[ -f "$HOME/build_duration/$pkg" ]] || continue

        size=
        du_pkg_pkg=

        if [[ -e "$CP/$pkg" ]]; then
            du_pkg_pkg=$pkg
        elif [[ -e "$CP/$pkg-bin" ]]; then
            du_pkg_pkg=$pkg-bin
        elif [[ "$pkg" == *-bin && -e "$CP/${pkg%-bin}" ]]; then
            du_pkg_pkg=${pkg%-bin}
        fi

        if [[ -n "$du_pkg_pkg" ]]; then
            size=$(du_pkg "$du_pkg_pkg" 2>/dev/null | awk '{print $1}')
        fi
        duration=$(sort -n "$HOME/build_duration/$pkg" |
            awk '{
                a[NR] = $1
            }
            END {
                if (NR == 0) print 0
                else if (NR % 2) print a[(NR + 1) / 2]
                else print (a[NR / 2] + a[NR / 2 + 1]) / 2
            }')
        time=$(med_build_time "$pkg" | sed "s/^$pkg: //")

        printf '%s\t%s\t%14s\t%s\n' "$duration" "$size" "$time" "$pkg"
    done |
    sort -nr -k1,1 |
    cut -f2- |
    {
        printf '%-6s  %-14s  %s\n' "Size" "Build duration" "Package"
        cat
    } |
    tee "$HOME/logs/pkgs_size_by_bd.log" |
    less -S
}

function ls_pkgs_bd_by_size {
    find "$LFP" -mindepth 2 -maxdepth 2 -name build.sh -printf '%h\n' |
    while read -r dir; do
        pkg=${dir##*/}
        [[ -f "$HOME/build_duration/$pkg" && -f "$CP/$pkg" ]] || continue

        size=
        du_pkg_pkg=

        if [[ -e "$CP/$pkg" ]]; then
            du_pkg_pkg=$pkg
        elif [[ -e "$CP/$pkg-bin" ]]; then
            du_pkg_pkg=$pkg-bin
        elif [[ "$pkg" == *-bin && -e "$CP/${pkg%-bin}" ]]; then
            du_pkg_pkg=${pkg%-bin}
        fi

        if [[ -n "$du_pkg_pkg" ]]; then
            size=$(du_pkg "$du_pkg_pkg" 2>/dev/null | awk '{print $1}')
        fi
        time=$(med_build_time "$pkg" | sed "s/^$pkg: //")

        printf '%s\t%14s\t%s\n' "$size" "$time" "$pkg"
    done |
    sort -rh -k1,1 |
    {
        printf '%-6s  %14s  %s\n' "Size" "Build duration" "Package"
        cat
    } |
    tee "$HOME/logs/pkgs_bd_by_size.log" |
    less -S
}

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

function btimes {
    cat $HOME/build_duration/$1
}

function shortbd {
	grep -rl '^[0-9]$' ~/build_duration
}
