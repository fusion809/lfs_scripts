#!/bin/bash
created=$(sudo tune2fs -l "$(findmnt -no SOURCE /)" |
    awk -F': ' '/Filesystem created/ {print $2}')

created_s=$(date -d "$created" +%s)
current_s=$(date +"%s")
#age_s=$(R -q -e "($current_s-$created_s)" | grep "^\[1\]" | cut -d ' ' -f 2)
#echo "age_s = $age_s"
years=0
months=0

while (( $(date -d "$created + $((years + 1)) years" +%s) <= current_s )); do
    ((years++))
done

while (( $(date -d "$created + $years years + $((months + 1)) months" +%s) <= current_s )); do
    ((months++))
done

base_s=$(date -d "$created + $years years + $months months" +%s)
remaining=$((current_s - base_s))

days=$((remaining / 86400))
remaining=$((remaining % 86400))

hours=$((remaining / 3600))
remaining=$((remaining % 3600))

minutes=$((remaining / 60))
seconds=$((remaining % 60))

if [[ "$years" -gt 0 ]]; then
	printf ' %02d/%02d/%02d %02d:%02d:%02d\n' \
    		"$days" "$months" "$years" \
    		"$hours" "$minutes" "$seconds"
else
	printf ' %02d/%02d %02d:%02d:%02d\n' \
    		"$days" "$months" \
    		"$hours" "$minutes" "$seconds"
fi
