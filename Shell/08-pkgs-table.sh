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
	local args=("$@")
	local sort_modes=()
	local arg mode opt
	local log_file
	local multiple=false

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

	# Remove duplicate sort modes while preserving their order.
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

	for sort_mode in "${sort_modes[@]}"
	do
		case "$sort_mode" in
			(a)
				log_file="$HOME/logs/pkgs_by_alpha.log"
				;;
			(t|b)
				log_file="$HOME/logs/pkgs_by_bd.log"
				;;
			(s)
				log_file="$HOME/logs/pkgs_by_size.log"
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
			elif [[ "$pkg" == "rust-bin" ]]; then
				size=$(cat "$HOME/logs/rust-bin-size.log")
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
		done |
		{
			case "$sort_mode" in
				(a)
					sort -t '	' -k3,3
					;;
				(t|b)
					sort -t '	' -k5,5gr
					;;
				(s)
					sort -t '	' -k6,6gr
					;;
			esac
		} |
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

			if (length(substr($4, 1, 100)) > max_version)
				max_version = length(substr($4, 1, 10))
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
		' > "$log_file"

		if [[ "$multiple" == false ]]
		then
			less -S "$log_file"
		fi
	done
}
