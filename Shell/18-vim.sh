function vbs {
	if [[ -f $LFP/$1/build.sh ]]; then
		vim $LFP/$1/build.sh
	elif [[ -f $LFP/uninstalled/$1/build.sh ]]; then
		vim $LFP/uninstalled/$1/build.sh
	else
		cbs "$1"
		vim $LFP/$1/build.sh
	fi
}

function vrm {
	vim README.md
}

function vsb {
	vim *.SlackBuild
}

function vsd {
	sudo vim /etc/sddm.conf
}

function vsh {
	vim $HOME/lfs-scripts/Shell/$1
}

function vzsh {
	vim $HOME/.zshrc
}
