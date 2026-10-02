#!/bin/bash
cat ~/logs/packages_no.log
pip=$(pip3 list | wc -l)
custom=$(ls /var/lib/custom-packages | wc -l)
R=$(Rscript -e 'ip <- installed.packages(); cat(ip[,1], sep="\n")' | wc -l)
julia=$(julia -e 'using Pkg; Pkg.status()' | grep -v "Project.toml" | wc -l)
total=$(($julia+$pip+$R+$custom))
echo "$total [ $custom,  $julia,  $pip,  $R]" > ~/logs/packages_no.log
