function fetcharch {
	wget -cqO- "https://gitlab.archlinux.org/archlinux/packaging/packages/$1/-/raw/main/PKGBUILD?ref_type=heads&inline=false"
}

function fetchaur {
	wget -cqO- "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1"
}
