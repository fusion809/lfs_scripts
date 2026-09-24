function bfail {
	grep -rl '^\[ERROR\]' ~/build_logs | cut -d '/' -f 5 | sort
}

function failmsg {
	if [[ -n $2 ]]; then
		grep -r '^\[ERROR\]' ~/build_logs/$1 -B $2
	else
		grep -r '^\[ERROR\]' ~/build_logs/$1 -B 20
	fi
}