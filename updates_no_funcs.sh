#!/bin/bash
LOG="$HOME/logs/updates.log"
LOG_TMP="$HOME/logs/updates.log.tmp"
DURATION_LOG="$HOME/logs/updates_duration.log"
MAX_AGE=5 # Maximum age of updates.log in minutes

if ! declare -f updates >/dev/null; then
    function updates {
        bash "$HOME/.lfs_scripts/lfs-updates.sh" "$@"
    }
fi

function silent_updates {
    local start_time=$(date +%s)
    echo "$start_time" > "${LOG_TMP}.start"
    if updates 2>&1 | tee "$LOG_TMP" > /dev/null; then
        mv "$LOG_TMP" "$LOG"
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "$duration" >> "$DURATION_LOG"
    else
        rm -f "$LOG_TMP"
    fi
    rm -f "${LOG_TMP}.start"
}

function updates_avg {
    local avg_duration_rnd=0
    if [[ -s "$DURATION_LOG" ]]; then
        avg_duration_rnd=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f\n", sum/count; else print 0}' "$DURATION_LOG")
        avg_duration_rnd=${avg_duration_rnd:-0}
    fi
    echo "$avg_duration_rnd"
}

function updates_iqr {
	sort -n "$HOME/logs/updates_duration.log" |
awk '
{
    a[NR] = $1
}
END {
    n = NR

    q1_pos = (n + 1) / 4
    q3_pos = 3 * (n + 1) / 4

    q1 = quartile(q1_pos)
    q3 = quartile(q3_pos)

    print q3 - q1
}
function quartile(pos,    lo, hi, frac) {
    lo = int(pos)
    hi = lo + 1
    frac = pos - lo

    if (lo < 1)
        return a[1]
    if (hi > n)
        return a[n]

    return a[lo] + frac * (a[hi] - a[lo])
}'
}

function updates_med {
	sort -n "$HOME/logs/updates_duration.log" |
awk '{
    a[NR] = $1
}
END {
    if (NR % 2)
        print a[(NR + 1) / 2]
    else
        print (a[NR / 2] + a[NR / 2 + 1]) / 2
}'
}

function log_is_recent {
    local avg_duration_rnd=$(updates_med)
    local threshold=$(( 300 - avg_duration_rnd ))
    local log_age=$(( $(date +%s) - $(date +%s -r "$LOG") ))
    (( threshold >= log_age ))
}

function update_if_needed {
    if [[ ! -f "$LOG" ]]; then
        # No log at all — refresh in background, print empty/zero stats now
        (
            flock -n 9 || exit
            [[ -f "$LOG" ]] || silent_updates
        ) >/dev/null 2>&1 9>"$LOG.lock" &
    elif ! log_is_recent; then
        # Log exists but stale — refresh in background, print stale data now
        (
            flock -n 9 || exit
            silent_updates
        ) >/dev/null 2>&1 9>"$LOG.lock" &
    fi
}

function read_log_stats {
    if [[ -f "$LOG" ]]; then
        read -r no_updates no_missing no_files_missing no_failed < <(awk '
            /\[UPDATE\]/ { u++ }
            /\[MISSING\]/ { m++ }
            /\[FILES MISSING\]/ { fm++ }
            /\[FAILED\]/ { f++ }
            END { printf "%d %d %d %d\n", u, m, fm, f }
        ' "$LOG")
        no_missing_total=$((no_missing + no_files_missing))
        mod_time=$(date -d "@$(stat -c %Y "$LOG")" "+%I:%M:%S %p")
    else
        no_updates=0
        no_missing_total=0
        no_failed=0
        mod_time="Never"
    fi
}

function progress_status {
    in_progress=""
    if [[ -f "$LOG_TMP" ]]; then
        in_progress="󰦕 "
        local percent=$(awk -v RS='[\r\n]' '/Global [0-9]+%/ { match($0, /Global ([0-9]+)%/, m); val = m[1] } END { print val }' "$LOG_TMP")
        if ! [[ -n $percent ]]; then
            percent="0"
        fi
        in_progress="󰦕 ${percent}% "
    fi
}

function failed_version {
    local failed_log="$HOME/logs/failed_versioning.log"
    if [[ -f "$failed_log" ]]; then
        local count=$(awk -F',' '!seen[$2]++ { count++ } END { print count+0 }' "$failed_log")
        echo " F$count"
    fi
}

function updates_avg_read {
	local time=$(updates_avg)
	local min=$(($time / 60))
	local sec=$(($time % 60))
	echo "${min}m${sec}s"
}

function updates_iqr_read {
	local time=$(updates_iqr)
	echo "${time}s"
}

function updates_med_read {
	local time=$(updates_med)
	local min=$(($time / 60))
	local sec=$(($time % 60))
	echo "${min}m${sec}s"
}
	
function print_status {
	echo "$in_progress󰔚 $(updates_med_read) ($(updates_iqr_read))  $mod_time  $no_updates 󰂕 $no_missing_total  ${no_failed}$(failed_version)"
}
