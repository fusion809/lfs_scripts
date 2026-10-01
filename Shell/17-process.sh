function pelaps {
	t1=$(date -d "$(pstart "$1")" +"%s")
	t2=$(date +"%s")
	s=$((t2-t1))
	printf '%02d:%02d:%02d\n' $(($s/3600)) $((($s%3600)/60)) $(($s%60))
}

function loop_pelaps {
	while ps ax | grep "$1" &> /dev/null;
	do
		dur=$(pelaps "$1")
		echo "$1 has taken $dur..."
		sleep 1
	done
	echo "Took a total of $dur for $1 to finish..."
}

function pelaps_live {
    local pid_or_name="$1"
    local start_str=$(pstart "$pid_or_name" | head -n 1)
    
    if [[ -z "$start_str" ]]; then
        echo "No process matching '$pid_or_name' found."
        return 1
    fi
    
    local t1=$(date -d "$start_str" +"%s")
    
    # Trap to ensure cursor is restored on Ctrl+C
    trap "printf '\e[?25h\n'; return" INT
    
    # Hide cursor
    printf "\e[?25l"

    while true; do
        # Check if process is still alive
        local alive=false
        if [[ "$pid_or_name" =~ ^[0-9]+$ ]]; then
            kill -0 "$pid_or_name" 2>/dev/null && alive=true
        else
            pgrep -f "$pid_or_name" >/dev/null 2>&1 && alive=true
        fi
        
        local t2=$(date +"%s")
        local s=$((t2-t1))
        
        # Print time with carriage return
        printf "\r%02d:%02d:%02d" $(($s/3600)) $((($s%3600)/60)) $(($s%60))
        
        if [[ "$alive" == "false" ]]; then
            # Print one last time and exit
            printf "\n"
            break
        fi
        
        sleep 1
    done
    
    # Restore cursor
    printf "\e[?25h"
    trap - INT
}

# Monitoring function for a single autobuild process
function elaps_build {
    local line=$(ps -eo pid,args | grep "autobuild.sh" | grep -v grep | head -n 1)
    if [[ -z "$line" ]]; then
        echo "Error: No active autobuild process found."
        return 1
    fi
    
    local pid=$(echo "$line" | awk '{print $1}')
    # Get the package name (the last argument of the command line)
    local pkg=$(echo "$line" | grep -oP '(?<=autobuild\.sh\s)\S+')
    
    echo "------------------------------------------------"
    echo "Currently building: $pkg (PID: $pid)"
    pelaps_live "$pid"
}

function pstart {
	ps -eo pid,lstart | grep  "$1" | sed "s/\s*$1 //g"
}


