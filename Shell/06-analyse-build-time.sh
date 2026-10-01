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

function iqr_build_time {
	local pkg=$1

	awk -F: -v pkg="$pkg" '
		function duration_seconds() {
			if (NF == 3)
				return $1 * 3600 + $2 * 60 + $3
			else if (NF == 2)
				return $1 * 60 + $2
			else
				return $1
		}

		{
			values[++n] = duration_seconds()
		}

		END {
			if (n < 2) {
				printf "%s: insufficient data\n", pkg
				exit
			}

			for (i = 1; i <= n; i++)
				for (j = i + 1; j <= n; j++)
					if (values[i] > values[j]) {
						tmp = values[i]
						values[i] = values[j]
						values[j] = tmp
					}

			q1_pos = (n + 1) / 4
			q3_pos = 3 * (n + 1) / 4

			if (q1_pos == int(q1_pos))
				q1 = values[q1_pos]
			else {
				lower = int(q1_pos)
				upper = lower + 1
				q1 = values[lower] + \
					(q1_pos - lower) * (values[upper] - values[lower])
			}

			if (q3_pos == int(q3_pos))
				q3 = values[q3_pos]
			else {
				lower = int(q3_pos)
				upper = lower + 1
				q3 = values[lower] + \
					(q3_pos - lower) * (values[upper] - values[lower])
			}

			iqr = int(q3 - q1 + 0.5)

			hours = int(iqr / 3600)
			minutes = int((iqr % 3600) / 60)
			remaining_seconds = iqr % 60

			if (hours > 0)
				printf "%s: %d:%02d:%02d\n", pkg, hours, minutes, remaining_seconds
			else if (minutes > 0)
				printf "%s: %d:%02d\n", pkg, minutes, remaining_seconds
			else
				printf "%s: %d\n", pkg, remaining_seconds
		}
	' "$HOME/build_duration/$pkg"
}

function btimes {
    cat $HOME/build_duration/$1
}