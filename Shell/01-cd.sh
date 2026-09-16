function cda {
	cd $ARC/$1
}

function cdap {
	cd ~/.local/share/applications
}

function cdbd {
	cd ~/build_duration/$1
}

function cdbl {
	cd ~/build_logs/$1
}

function cdbp {
	cd $BP/$1
}

function cdcp {
	cd $CP/$1
}

function cddo {
	cd $HOME/Downloads
}

function cdge {
	cd /usr/share/gnome-shell/extensions/$1
}

function cde {
	cdge executor@raujonas.github.io/$1
}

function cdi {
	cd ~/.local/share/icons/$1
}

function cdl {
	cd ~/logs/$1
}

function cdld {
	cd ~/lfs_dotfiles/$1
}

function cdle {
	cd ~/.local/share/gnome-shell/extensions/$1
}

function cdlfa {
	cd ~/lfs_apps/$1
}

function cdlfp_base {
	cd ~/lfs_packaging/$1
}
function cdlfp {
	if [[ -z "$1" ]]; then
		cdlfp_base
		return;
	fi
	if [[ -d "$HOME/lfs_packaging/$1" ]]; then
		cdlfp_base "$1"
		return;
	fi
	if [[ -f /var/lib/book-packages/$1 ]]; then
		mv /var/lib/book-packages/$1 /var/lib/custom-packages
	fi
	mkdir -p ~/lfs_packaging/$1
	cdlfp_base "$1"
	if [[ "$1" == *"github"* ]] || [[ "$2" == "github" ]]; then
		if [[ "$3" == "cmake" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://github.com/\$repo/releases/download/\$direname/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
cmake_options=(-D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release         \
      -D BUILD_TESTING=OFF)
cmaki "\${cmake_options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
elif [[ "$3" == "meson" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://github.com/\$repo/releases/download/\$direname/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
meson_options=(--prefix=/usr       \
            --buildtype=release \
	    -D tests=false)
mni "\${meson_options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
else
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://github.com/\$repo/releases/download/\$direname/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
cmi --prefix=/usr --disable-static
cd ../
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
		fi		
	elif [[ "$2" == "cmake" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://github.com/\$repo/releases/download/\$direname/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
cmake_options=(-D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release         \
      -D BUILD_TESTING=OFF)
cmaki "\${cmake_options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
	elif [[ "$2" == "meson" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
meson_options=(--prefix=/usr       \
            --buildtype=release \
	    -D tests=false)
mni "\${meson_options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
	elif [[ "$1" == *"gnome"* ]] || [[ "$2" == "gnome" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=GNOME/\$name
version=\$(gh_ver \$repo)
majVer=\$(echo \$version | sed -E 's/\.[0-9]+\$//g')
filename="\$name-\$version.tar.xz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://download.gnome.org/sources/\$name/\$majVer/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
options=(--prefix=/usr --buildtype=release)
mni "\${options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
	elif [[ "$1" == *"kde"* ]] || [[ "$2" == "kde" ]]; then
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=KDE/\$name
version=\$(gh_ver \$repo)
majVer=\$(echo \$version | sed -E 's/\.[0-9]+\$//g')
filename="\$name-\$version.tar.xz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://download.kde.org/stable/release-service/\$version/src/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
options=(-D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release         \
      -D BUILD_TESTING=OFF)
cmaki "\${options[@]}"
cd ../..
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
	else
		cat > build.sh <<EOF
#!/bin/bash
set -e
name=$1
repo=\$name/\$name
version=\$(gh_ver \$repo)
filename="\$name-\$version.tar.gz"
direname="\${filename/.tar.*/}"
if ! [[ -f \$filename ]]; then
	wget -c https://github.com/\$repo/releases/download/\$direname/\$filename
fi
rm -rf "\$direname"
tar xf "\$filename"
cd "\$direname"
cmi --prefix=/usr --disable-static
cd ../
rm -rf "\$filename" "\$direname"
echo "\$version" | sudo tee "/var/lib/custom-packages/\$name"
EOF
	fi
	chmod +x build.sh
	echo "build.sh created based on template..."
	if [[ -f /var/lib/custom-packages/$1 ]]; then
		add_deps "$1"
	fi
	vim build.sh
}

alias cdlp=cdlfp

function cdlfs {
	cd ~/lfs-scripts/$1
}

function cdlg {
	cd ~/lfs_gnuplot/$1
}

function cdp {
	cd ~/plots/$1
}

function cdps {
	cd ~/Screenshots/$1
}

function cds {
	cd $SRC/$1
}

function cdsap {
	cd /usr/share/applications
}

function cdsh {
	cdlfs "Shell/$1"
}

function cdw {
	cd ~/wallpapers
}
