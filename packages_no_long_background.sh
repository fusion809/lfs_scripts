#!/bin/bash
export LFP=$HOME/lfs_packaging
export CP=/var/lib/custom-packages
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
	uninst=$(zsh -ic "uninst_pkgs" | grep -v installed | wc -l)
	julia=$(julia -e 'using Pkg; Pkg.status()' | grep -v "Project.toml" | wc -l)
	npm=$(npm list -g --depth=0 | grep "@" | wc -l)
	total=$(($julia+$pip+$R+$CN+$npm))
	echo "$total [ $CN (󰊢 $CP)  $julia  $npm  $pip  $R] (i);  $uninst (u)." > ~/logs/packages_no_long.log
fi
echo "$CH" > ~/logs/custom_hash.log
