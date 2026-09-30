source $HOME/.lfs_scripts/21-lfs.sh

# lfs_autobuild: run the host's latest lfs-autobuild.sh (synced to ~/.lfs_autobuild.sh by the host)
function autobuild {
    bash ~/.lfs_autobuild.sh "$@"
}
source ~/.lfs_scripts/lfs-vm-bootstrap.sh 2>/dev/null
eval "$(pay-respects zsh --alias)"

function no_inst_pkgs {
    ls $CP | wc -l
}

function no_build_pkgs {
    ls $HOME/build_duration | wc -l
}

function ls_pkgs {
    find $LFP -mindepth 2 -maxdepth 2 -name "build.sh" -type f \
    | sed "s|$LFP/||g" | cut -d '/' -f 1 | sort
}

function no_pkgs {
    ls_pkgs | wc -l
}

function uninst_pkgs {
    ls_pkgs |
    while read -r pkg; do
        if [[ -e "$CP/$pkg" ]]; then
            continue
        elif [[ "$pkg" == *-bin && -e "$CP/${pkg%-bin}" ]]; then
            printf '%s (%s installed)\n' "$pkg" "${pkg%-bin}"
        elif [[ "$pkg" != *-bin && -e "$CP/${pkg}-bin" ]]; then
            printf '%s (%s installed)\n' "$pkg" "${pkg}-bin"
        else
            printf '%s\n' "$pkg"
        fi
    done

}

function miss_pkgs {
	uninst_pkgs | grep -v "installed"
}
