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

    size=$(du_pkg "$pkg" | awk '{print $1}')
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
less -S
}

function ls_pkgs_bd_by_size {
find "$LFP" -mindepth 2 -maxdepth 2 -name build.sh -printf '%h\n' |
while read -r dir; do
    pkg=${dir##*/}
    [[ -f "$HOME/build_duration/$pkg" ]] || continue

    size=$(du_pkg "$pkg" | awk '{print $1}')
    time=$(med_build_time "$pkg" | sed "s/^$pkg: //")

    printf '%s\t%14s\t%s\n' "$size" "$time" "$pkg"
done |
sort -rh -k1,1 |
{
    printf '%-6s  %14s  %s\n' "Size" "Build duration" "Package"
    cat
} |
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

function cbtime {
    local jobs=$(ps ax | grep "autobuild\.sh" | grep -v "grep.*autobuild.sh")
    if [[ -n "$jobs" ]]; then
		echo "autobuild job(s):"
    else
		exit 1
    fi
    while IFS= read -r job; do
        local elapsed=$(btime_elapsed "$job")
        local pkg=$(pkg_from_job "$job")
        local perc=$(R_eval "round($elapsed/$(med_build_time_sec $pkg)*100)" )
        printf '%s time elapsed: %02d:%02d:%02d (%s%% completed)' \
            $pkg \
            $((elapsed / 3600)) \
            $(((elapsed % 3600) / 60)) \
            $((elapsed % 60)) \
        $perc
    done <<< $jobs
}

function btimes {
    cat $HOME/build_duration/$1
}

function shortbd {
	grep -rl '^[0-9]$' ~/build_duration
}