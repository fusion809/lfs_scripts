function dconfD {
	cde
	dconf dump /org/gnome/shell/extensions/executor/ > executor-settings.dconf
	push "Updating dconf dump"
	cd -
}


function gnomBoot {
	sudo sed -i -e "6s|Session=plasma|#Session=plasma|g" -e "7s|#Session=gnome|Session=gnome|g" /etc/sddm.conf
}

function gnomRb {
	gnomBoot
	sudo reboot
}

function gnomSw {
	gnomBoot
	sudo systemctl restart sddm
}

if [[ "$(gsettings get org.gnome.shell disable-user-extensions)" == "true" ]]; then
	gsettings set org.gnome.shell disable-user-extensions false
fi

