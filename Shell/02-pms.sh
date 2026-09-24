source $HOME/.lfs_scripts/21-lfs.sh

# lfs_autobuild: run the host's latest lfs-autobuild.sh (synced to ~/.lfs_autobuild.sh by the host)
function autobuild {
    bash ~/.lfs_autobuild.sh "$@"
}
source ~/.lfs_scripts/lfs-vm-bootstrap.sh 2>/dev/null