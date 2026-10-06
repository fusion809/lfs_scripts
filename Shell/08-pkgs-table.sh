function pkgs_table_help {
    cat <<'EOF'
Usage: pkgs_table [-a|-t|-b|-s]

Generate a table of packages with their installed size, build duration, 
version and description, writing it to $HOME/logs/pkgs_by_$sort.log and 
opening the log in less.

Arguments:
    -a  sort alphabetically (default). In this case, $sort is `alpha`.
    -t  sort by build duration (descending). In this case, $sort is `bd`.
    -b  sort by build duration (descending). In this case, $sort is `bd`.
    -s  sort by package size (descending). In this case, $sort is `size`.

Multiple different conflicting arguments can be combined, e.g. 
`pkgs_table -ats` or `pkgs_table -a -t -s`, in this event `less` is not used 
to open the logs but the logs for each of the arguments is created. 
EOF
}

function pkgs_table {
	logs=(
		"$HOME/logs/pkgs_by_alpha.log"
		"$HOME/logs/pkgs_by_size.log"
		"$HOME/logs/pkgs_by_bd.log"
	)

	latest_log_time=$(
	    stat -c '%Y' "${logs[@]}" |
	    sort -n |
	    tail -n1
	)

	since=$((latest_log_time - 180))
	if ! ( find $CP $LFP \
		-path $CP/.git -prune -o \
		-path $LFP/.git -prune -o \
		-type f -newermt "@$since" -print -quit |
		grep -q . ); then
		echo "$CP does not show any likely updates to the table."
		return 1
	fi
	local args=("$@")
	local sort_modes=()
	local arg mode opt sort_mode
	local log_file
	local multiple=false
	local tmpfile
	local sorted_tmpfile

	if [[ ${#args[@]} -eq 0 ]]
	then
		pkgs_table_help
		return 0
	fi

	for arg in "${args[@]}"
	do
		case "$arg" in
			-h|--help)
				pkgs_table_help
				return 0
				;;
			-*)
				arg=${arg#-}

				while [[ -n "$arg" ]]
				do
					opt=${arg%"${arg#?}"}
					arg=${arg#?}

					case "$opt" in
						a|t|b|s)
							sort_modes+=("$opt")
							;;
						*)
							pkgs_table_help
							return 1
							;;
					esac
				done
				;;
			*)
				pkgs_table_help
				return 1
				;;
		esac
	done

	local unique_modes=()

	for mode in "${sort_modes[@]}"
	do
		if [[ ! " ${unique_modes[*]} " == *" $mode "* ]]
		then
			unique_modes+=("$mode")
		fi
	done

	sort_modes=("${unique_modes[@]}")

	if (( ${#sort_modes[@]} > 1 ))
	then
		multiple=true
	fi

	tmpfile=$(mktemp) || return 1

	find "$LFP" -mindepth 2 -maxdepth 2 -name build.sh -printf '%h\n' |
	while read -r dir
	do
		pkg=${dir##*/}
		logfile="$HOME/logs/$pkg.log"

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
			ver_pkg=$pkg-bin
			uninstalled=' (u)'
		elif [[ "$pkg" == *-bin && -e "$CP/${pkg%-bin}" ]]
		then
			du_pkg_pkg=${pkg%-bin}
			ver_pkg=${pkg%-bin}
			uninstalled=' (u)'
		else
			uninstalled=' (u)'
		fi

		if [[ -f "$logfile" ]]
		then
			size=$(tail -n 1 "$logfile")
		elif [[ "$pkg" == "julia-bin" && -f "$HOME/logs/julia-bin-size.log" ]]
		then
			size=$(cat "$HOME/logs/julia-bin-size.log")
		elif [[ -n "$du_pkg_pkg" ]]
		then
			size=$(du_pkg "$du_pkg_pkg" 2>/dev/null | awk 'NR == 1 {print $1}')
			[[ -n "$size" ]] || size=-
		else
			size=-
		fi

		if [[ -f "$logfile" ]]
		then
			version=$(head -n 1 "$logfile")
		elif [[ "$pkg" == "firefox" && -n "$uninstalled" ]]
		then
			version=$(lfs_ver firefox 2>/dev/null)
		elif [[ -n "$ver_pkg" ]]
		then
			version=$(pkgver "$ver_pkg" 2>/dev/null)
			[[ -n "$version" ]] || version=$(upver "$pkg" 2>/dev/null)
		else
			version=$(upver "$pkg" 2>/dev/null)
		fi

		[[ -n "$version" ]] || version=-

		if [[ -f "$HOME/build_duration/$pkg" ]]
		then
			time=$(med_build_time "$pkg" | sed "s/^$pkg: //")
			[[ -n "$time" ]] || time=-
		else
			time=-
		fi

		description=$(pkgdesc "$pkg")
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
	done > "$tmpfile"

	for sort_mode in "${sort_modes[@]}"
	do
		sorted_tmpfile=$(mktemp) || {
			rm -f "$tmpfile"
			return 1
		}

		case "$sort_mode" in
			a)
				log_file="$HOME/logs/pkgs_by_alpha.log"
				sort -t '	' -k3,3 "$tmpfile" > "$sorted_tmpfile"
				;;
			t|b)
				log_file="$HOME/logs/pkgs_by_bd.log"
				sort -t '	' -k5,5gr "$tmpfile" > "$sorted_tmpfile"
				;;
			s)
				log_file="$HOME/logs/pkgs_by_size.log"
				sort -t '	' -k6,6gr "$tmpfile" > "$sorted_tmpfile"
				;;
		esac

		awk -F '\t' '
		{
			size[NR] = $1
			time[NR] = $2
			pkg[NR] = $3
			version[NR] = substr($4, 1, 10)
			desc[NR] = $7

			if (length($1) > max_size)
				max_size = length($1)

			if (length($2) > max_time)
				max_time = length($2)

			if (length($3) > max_pkg)
				max_pkg = length($3)

			if (length(version[NR]) > max_version)
				max_version = length(version[NR])
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
		' "$sorted_tmpfile" > "$log_file"

		rm -f "$sorted_tmpfile"

		if [[ "$multiple" == false ]]
		then
			less -S "$log_file"
		fi
	done

	rm -f "$tmpfile"
}

function logs_commit {
	pushd ~/logs
	push "Updating pkgs_table outputs"
	popd
}

function pkgs_by {
	less $HOME/logs/pkgs_by_"$1".log
}
