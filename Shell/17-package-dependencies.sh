function pkgdep {
	if [[ -f $LFP/$1/build.sh ]]; then
		local pkgname=$1
	else
		echo "pkgdep takes a package name and returns the dependencies " \
		"of that package."
		return 1
	fi
	grep -r "depends=" $LFP/$pkgname/build.sh | cut -d '(' -f 2 \
	       | cut -d ')' -f 1
}

function pkgrevdep {
	if [[ -f $LFP/$1/build.sh ]]; then
		local pkgname=$1
	else
		echo "pkgrevdep takes a package name and returns the package(s) that " \
		     "depend upon it based on the contents of their build.sh file."
		return 1
	fi
	grep --include="build.sh" -R "depends=.*$pkgname" $LFP \
		| sed "s|$LFP/||g" | cut -d '/' -f 1 | sort
}