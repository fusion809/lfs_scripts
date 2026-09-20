export LANG=en_AU.UTF-8
export BP=/var/lib/book-packages
export CP=/var/lib/custom-packages
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rustc/lib:/opt/jdk/lib:/opt/qt6/lib:/opt/texlive/2025/lib
export LFP="$HOME/lfs_packaging"
export LFS="$HOME/lfs-scripts"
export LFD="$HOME/lfs_dotfiles"
export PATH=$PATH:/opt/rustc/bin:/opt/jdk/bin:/opt/qt6/bin:/opt/texlive/2025/bin/x86_64-linux:/sbin:/usr/sbin:$HOME/.juliaup/bin
export QT6PREFIX=/opt/qt6
export SRC="/sources"
export ARC="$SRC/archives"
export timestamp=$(uptime -s)
export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=/usr"
export ZSH_HIGHLIGHT_STYLES[comment]="fg=cyan,dimmed"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
