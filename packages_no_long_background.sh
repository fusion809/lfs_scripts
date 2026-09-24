#!/bin/bash
function hash {
	git -C /var/lib/$1-packages rev-parse --short HEAD
}

function stHash {
	cat ~/logs/$1_hash.log
}

function nopkg {
	ls /var/lib/$1-packages | wc -l
}

function comno {
	git -C /var/lib/$1-packages rev-list --branches master --count
}

CH=$(hash custom);
CN=$(nopkg custom);
CP=$(comno custom); 

if [[ $CH != "$(stHash custom)" ]]; then
	pip=$(pip3 list | wc -l)
	R=$(Rscript -e 'ip <- installed.packages(); cat(ip[,1], sep="\n")' | wc -l)
	julia=$(julia -e 'using Pkg; Pkg.status()' | grep -v "Project.toml" | wc -l)
	total=$(($julia+$pip+$R+$CN))
	echo "$total [  $CN (󰊢 $CP)  $julia  $pip  $R]" > ~/logs/packages_no_long.log
fi
echo "$CH" > ~/logs/custom_hash.log
