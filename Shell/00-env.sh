export LANG=en_AU.UTF-8
export BP=/var/lib/book-packages
export CP=/var/lib/custom-packages
export TEXLIVE_PREFIX=/opt/texlive/2026
export SAGE_ROOT=/opt/sage
export VENV_ROOT=$(ls $SAGE_ROOT/var/lib/sage/venv-python* -ld | rev \
| cut -d ' ' -f 1 | rev)
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rustc/lib:/opt/jdk/lib:\
	/opt/qt6/lib:$SAGE_ROOT/lib:$VENV_ROOT/lib:$TEXLIVE_PREFIX/lib"
export LFP="$HOME/lfs_packaging"
export LFS="$HOME/lfs-scripts"
export LFD="$HOME/lfs_dotfiles"
export PATH="$PATH:/opt/rustc/bin:/opt/jdk/bin:/opt/qt6/bin:$SAGE_ROOT/bin:\
	$VENV_ROOT/bin:$TEXLIVE_PREFIX/bin/x86_64-linux:/sbin:/usr/sbin"
export QT6PREFIX=/opt/qt6
export SRC="/sources"
export ARC="$SRC/archives"
export timestamp=$(uptime -s)
export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=/usr"
export ZSH_HIGHLIGHT_STYLES[comment]="fg=cyan,dimmed"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
