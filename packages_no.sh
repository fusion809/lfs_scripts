#!/bin/bash
cat ~/logs/packages_no.log
(
	pip=$(pip3 list 2>/dev/null | wc -l)
	custom=$(ls /var/lib/custom-packages 2>/dev/null | wc -l)
	R=$(Rscript -e "ip <- installed.packages(); cat(ip[,1], sep=\"\n\")" 2>/dev/null | wc -l)
	julia=$(julia -e "using Pkg; Pkg.status()" 2>/dev/null | grep -v "Project.toml" | wc -l)
	npm=$(npm list -g --depth=0 | grep "@" | wc -l)
	total=$(($julia+$npm+$pip+$R+$custom))
	echo "$total [ $custom,  $julia,  $npm,  $pip,  $R]" > ~/logs/packages_no.log
) >/dev/null 2>&1 &
