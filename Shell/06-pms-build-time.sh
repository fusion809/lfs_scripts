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

function desc {
	cat $LFP/$1/build.sh | grep "^description=" | cut -d '"' -f 2
}

function pkgs_table {
	local sort_mode=${1:--a}
	local log_file

	case "$sort_mode" in
		(-a)
			log_file="$HOME/logs/pkgs_by_alpha.log"
			;;
		(-t | -b)
			log_file="$HOME/logs/pkgs_by_bd.log"
			;;
		(-s)
			log_file="$HOME/logs/pkgs_by_size.log"
			;;
		(*)
			printf 'Usage: pkgs_table [-a|-t|-b|-s]\n' >&2
			printf '  -a  sort alphabetically (default)\n' >&2
			printf '  -t  sort by build duration (descending)\n' >&2
			printf '  -b  sort by build duration (descending)\n' >&2
			printf '  -s  sort by package size (descending)\n' >&2
			return 1
			;;
	esac

	find "$LFP" -mindepth 2 -maxdepth 2 -name build.sh -printf '%h\n' |
	while read -r dir
	do
		pkg=${dir##*/}
		build_file="$dir/build.sh"

		uninstalled=
		du_pkg_pkg=
		ver_pkg=

		if [[ -e "$CP/$pkg" ]]
		then
			du_pkg_pkg=$pkg
			ver_pkg=$pkg
		elif [[ -e "$CP/$pkg-bin" ]]
		then
			du_pkg_pkg=$pkg-bin
			uninstalled=' (u)'
		elif [[ "$pkg" == *-bin && -e "$CP/${pkg%-bin}" ]]
		then
			du_pkg_pkg=${pkg%-bin}
			uninstalled=' (u)'
		else
			uninstalled=' (u)'
		fi

		if [[ "$pkg" == "julia-bin" ]]
		then
			size=$(cat "$HOME/logs/julia-bin-size.log")
		elif [[ -n "$du_pkg_pkg" ]]
		then
			size=$(du_pkg "$du_pkg_pkg" 2>/dev/null | awk 'NR == 1 {print $1}')
			[[ -n "$size" ]] || size=-
		else
			size=-
		fi

		if [[ -n "$uninstalled" ]]
		then
			version=$(upver "$pkg" 2>/dev/null)
			[[ -n "$version" ]] || version=-
		elif [[ -n "$ver_pkg" ]]
		then
			version=$(pkgver "$ver_pkg")
			[[ -n "$version" ]] || version=-
		else
			version=-
		fi

		if [[ -f "$HOME/build_duration/$pkg" ]]
		then
			time=$(med_build_time "$pkg" | sed "s/^$pkg: 0//")
			[[ -n "$time" ]] || time=-
		else
			time=-
		fi

		description=$(desc "$pkg")
		[[ -n "$description" ]] || description=-

		display_pkg="$pkg$uninstalled"

		if [[ "$size" == "-" ]]
		then
			size_sort=0
		else
			size_sort=$(awk -v s="$size" '
				BEGIN {
					if (s ~ /KiB$/) {
						sub(/KiB$/, "", s)
						print s * 1024
					} else if (s ~ /MiB$/) {
						sub(/MiB$/, "", s)
						print s * 1024 * 1024
					} else if (s ~ /GiB$/) {
						sub(/GiB$/, "", s)
						print s * 1024 * 1024 * 1024
					} else if (s ~ /TiB$/) {
						sub(/TiB$/, "", s)
						print s * 1024 * 1024 * 1024 * 1024
					} else {
						print s
					}
				}
			')
		fi

		if [[ "$time" == "-" ]]
		then
			time_sort=0
		else
			time_sort=$(awk -F: '{
				if (NF == 3)
					print $1 * 3600 + $2 * 60 + $3
				else if (NF == 2)
					print $1 * 60 + $2
				else
					print $1
			}' <<< "$time")
		fi

		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
			"$size" "$time" "$display_pkg" "$version" \
			"$time_sort" "$size_sort" "$description"
	done |
	{
		case "$sort_mode" in
			(-a)
				sort -t '	' -k3,3
				;;
			(-t | -b)
				sort -t '	' -k5,5gr
				;;
			(-s)
				sort -t '	' -k6,6gr
				;;
		esac
	} |
	awk -F '\t' '
	{
		size[NR] = $1
		time[NR] = $2
		pkg[NR] = $3
		version[NR] = $4
		desc[NR] = $7

		if (length($1) > max_size)
			max_size = length($1)

		if (length($2) > max_time)
			max_time = length($2)

		if (length($3) > max_pkg)
			max_pkg = length($3)

		if (length($4) > max_version)
			max_version = length($4)
	}
	END {
		if (length("Size") > max_size)
			max_size = length("Size")

		if (length("Time") > max_time)
			max_time = length("Time")

		if (length("Package") > max_pkg)
			max_pkg = length("Package")

		if (length("Version") > max_version)
			max_version = length("Version")

		printf "%*s %-*s %-*s %-*s %s\n",
			max_size, "Size",
			max_time, "Time",
			max_pkg, "Package",
			max_version, "Version",
			"Description"

		for (i = 1; i <= NR; i++)
			printf "%*s %-*s %-*s %-*s %s\n",
				max_size, size[i],
				max_time, time[i],
				max_pkg, pkg[i],
				max_version, version[i],
				desc[i]
	}
	' |
	tee "$log_file" |
	less -S
}
