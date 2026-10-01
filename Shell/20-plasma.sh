function plasBoot {
	sudo sed -i -e "6s|#Session=plasma|Session=plasma|g" -e "7s|Session=gnome|#Session=gnome|g" /etc/sddm.conf
}

function plasRb {
	plasBoot
	sudo reboot
}

function plasSw {
	plasBoot
	sudo systemctl restart sddm
}


function percPlasm {
	lines=$(cat /sources/archives/plasma*.md5 | grep -v "^#")
	linesno=$(echo $lines | wc -l)

	Reval "($(echo $lines | grep -B 100 "$1" | wc -l)-1)/$linesno"
}


if ! [[ -f $HOME/plots/$timestamp.svg ]]; then
	plot
fi

