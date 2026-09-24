function updates_avg {
    local avg_duration_rnd=0
    if [[ -s "$DURATION_LOG" ]]; then
        avg_duration_rnd=$(awk '{sum+=$1; count++} END {if (count) printf "%.0f\n", sum/count; else print 0}' "$DURATION_LOG")
        avg_duration_rnd=${avg_duration_rnd:-0}
    fi
    echo "$avg_duration_rnd"
}

function updates_avg_read {
	local time=$(updates_avg)
	local min=$(($time / 60))
	local sec=$(($time % 60))
	echo "${min}m${sec}s"
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

function updates_iqr_read {
	local time=$(R_eval "round($(updates_iqr))")
	echo "${time}s"
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

function updates_med_read {
	local time=$(updates_med)
	local min=$(R_eval "floor($time / 60)")
	local sec=$(R_eval "round($time %% 60)")
	echo "${min}m${sec}s"
}