function clipf {
	if [[ $XDG_SESSION_TYPE == "x11" ]]; then
		xclip -sel clip < "$@"
	else
		cat "$@" | wl-copy
	fi
}

function os-release {
	cat /etc/os-release | grep "PRETTY_NAME" | cut -d '"' -f 2
}

alias os_info=os-release
alias os-info=os-release

function srcs {
	sudo du -h --max-depth=0 $SRC/* | sort -h
}

function szsh {
	source $HOME/.zshrc
}

function update-grub {
	sudo /sbin/grub-mkconfig -o /boot/grub/grub.cfg
}

function upos {
	~/.lfs_scripts/upos.sh
}

OSYS=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d '"' -f 2 | cut -d '/' -f 1)

local_time=$(date +"%a, %d %b %Y %R:%S" -u)
google_time="$(curl -sI https://google.com | grep -i '^date:' | sed 's/^[Dd]ate: //g')"

if [[ "$local_time" != "${google_time/ GMT/}" ]]; then
	sudo date -s "$google_time" > /dev/null
fi

function walloptim {
	find ~/wallpapers -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) \
		-exec jpegoptim --strip-all --all-progressive {} +
}
source ~/lfs_packaging/shared-funcs.sh

function lib_dir_size {
	find /usr/lib -mindepth 1 -maxdepth 1 -type d -exec du -sh {} + | sort -h
}
