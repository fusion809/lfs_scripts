#!/bin/bash
while :;
do
	diff=$(($(date +"%s")-$(cat $HOME/logs/lfs-time.log)))
	if [[ $diff -ge 300 ]]; then
		rm $HOME/.cache/*index.html
		wget -c https://www.linuxfromscratch.org/lfs/view/systemd/index.html -O $HOME/.cache/lfs-index.html
		wget -c https://www.linuxfromscratch.org/blfs/view/systemd/index.html -O $HOME/.cache/blfs-index.html
		wget -c https://www.linuxfromscratch.org/blfs/view/systemd/longindex.html -O $HOME/.cache/blfs-longindex.html
		wget -c https://www.linuxfromscratch.org/slfs/view/stable/ -O $HOME/.cache/slfs-index.html
		wget -c https://www.linuxfromscratch.org/blfs/view/systemd/postlfs/mitkrb.html -O $HOME/.cache/blfs-mitkrb.html
		wget -c https://www.linuxfromscratch.org/blfs/view/systemd/gnome/vte.html -O $HOME/.cache/blfs-vte.html
		for categ in app driver lib font
		do
			wget -c https://www.linuxfromscratch.org/blfs/view/systemd/x/x7$categ.html -O "$HOME/.cache/blfs-x7$categ.html"
		done
		echo "$(date +"%s")" > $HOME/logs/lfs-time.log
	fi

done
