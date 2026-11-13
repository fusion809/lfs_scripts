function bfail {
	grep -rl '^\[ERROR\]' ~/build_logs | cut -d '/' -f 5 | sort
}

function failmsg {
	local logfile="$HOME/build_logs/$1"
	local lines=30
	if [[ "$2" =~ ^[0-9]+$ ]]; then
		lines="$2"
	fi
	if [[ ! -f "$logfile" ]]; then
		printf 'Build log not found: %s\n' "$logfile" >&2
		return 1
	fi
	tail -n "$lines" -- "$logfile" | tr -d '\000'
}
