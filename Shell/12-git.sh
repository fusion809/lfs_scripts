function start_agent {
	eval ssh-agent $SHELL
	ssh-add ~/.ssh/aur
 	ssh-add ~/.ssh/id_rsa
}

# Switch to SSH
function gitsw {
	# repo is the name of the repository
	if git remote -v | grep origin &> /dev/null ; then
		repo=$(git remote -v | grep origin | sed 's/.*\///g' | sed 's/.git.*//g' | sed 's/ (fetch)//g' | head -n 1)
		git remote rm origin
	else
		repo=${PWD##*/}
	fi

  	if [[ -n "$1" ]]; then
		git remote add origin git@github.com:fusion809/"${1}".git
	else
		git remote add origin git@github.com:fusion809/"${repo}".git
	fi
}

alias SSH=gitsw
alias gitssh=gitsw
alias gits=gitsw

function gtsa {
	for i in $GHUBM/*/*
	do
		pushd $i || return
		gitsw
		popd || return
	done
}

function update_git_repo {
	if [[ -n "$2" ]]; then
		git -C "$1" pull "$2" $(git-branch "$1") -q
	elif [[ -n "$1" ]]; then
		git -C "$1" pull origin $(git-branch "$1") -q
	else
		git pull origin "$(git-branch)" -q
	fi
}

function current_git_branch {
	if ! [[ -n "$1" ]]; then
		git rev-parse --abbrev-ref HEAD
	else
		git -C "$1" rev-parse --abbrev-ref HEAD
	fi
}

alias git-branch=current_git_branch

function git_checkout {
	git -C "$1" checkout "$2"
}

function latest_commit_number {
	update_git_repo "$1"
	if ! [[ -n "$1" ]]; then
		git rev-list --branches "$(git-branch)" --count
	else
		git -C "$1" rev-list --branches "$(git-branch "$1")" --count
	fi
}

alias comno=latest_commit_number

function pushop {
	if [[ -n "$1" ]]; then
		git push origin "$(git-branch)" "$1"
	else
		git push origin "$(git-branch)"
	fi
}

## Minimal version
function pushm {
	git add --all										# Add all files to git
	git commit -m "$1"								   # Commit with message = argument 1
	pushop										 # Push to the current branch
}

function pushme {
	git add --all
	git commit --edit
	pushop "$1"
}

function pushmf {
	git add --all
	git commit -m "$1"
	git push origin $(git-branch) -f
}

function pusht {
	git add --all
	git commit -m "$1"
	if [[ -n $2 ]]; then
		 git tag "$2"
		 git push origin "$2"
	else
		 git tag "$(latest_commit_number)"
		 git push origin "$(latest_commit_number)"
	fi
	git push origin "$(git-branch)"
}

# Complete push
function push {
	if [[ -d .git ]] || ( git log &> /dev/null ); then
		if echo "$PWD" | grep opendesktop > /dev/null 2>&1 ; then
			 commc=$(git rev-list --branches master --count)
			 commn=$(octave_evaluate "$commc+1")
			 sed -i -e "s/PKGVER=[0-9]*/PKGVER=${commn}/g" "$PK"/opendesktop-app/pkg/appimage/appimagebuild
			 pushm "$1"
		else
			 pushm "$1"
		fi

		if echo "$PWD" | grep "$HOME/Shell" > /dev/null 2>&1 ; then
			 szsh
		elif echo "$PWD" | grep "$FS" > /dev/null 2>&1 && grep -i Fedora < /etc/os-release > /dev/null 2>&1 ; then
			 szsh
		elif echo "$PWD" | grep "$ARS" > /dev/null 2>&1 && grep -i Arch < /etc/os-release  > /dev/null 2>&1 ; then
			 szsh
		elif echo "$PWD" | grep "$GS" > /dev/null 2>&1 && grep -i Gentoo < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$DS" > /dev/null 2>&1 && grep -i "Debian\|Ubuntu" < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$VS" > /dev/null 2>&1 && grep -i Void < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$OSS" > /dev/null 2>&1 && grep -i openSUSE < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$NS" > /dev/null 2>&1 && grep -i NixOS < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$PLS" > /dev/null 2>&1 && grep -i PCLinuxOS < /etc/os-release > /dev/null 2>&1; then
			 szsh
		elif echo "$PWD" | grep "$CS" > /dev/null 2>&1 && grep -i CentOS < /etc/os-release > /dev/null 2>&1; then
			 szsh
		fi

	fi
}

# Complete push, but with potentially more detailed commit message
function pushe {
	if echo "$PWD" | grep opendesktop > /dev/null 2>&1 ; then
		 commc=$(git rev-list --branches master --count)
		 commn=$(octave_evaluate "$commc+1")
		 sed -i -e "s/PKGVER=[0-9]*/PKGVER=${commn}/g" "$PK"/opendesktop-app/pkg/appimage/appimagebuild
		 pushme "$1"
	elif echo "$PWD" | grep OpenRA > /dev/null 2>&1 ; then
		 commc=$(git rev-list --branches bleed --count)
		 commn=$(octave_evaluate "$commc+1")
		 sed -i -e "s/COMNO=[0-9]*/COMNO=${commn}/g" "$PK"/OpenRA/packaging/linux/buildpackage.sh
		 pushme "$1"
	else
		 pushme "$1"
	fi

	if echo "$PWD" | grep "$HOME/Shell" > /dev/null 2>&1 ; then
		 szsh
	elif echo "$PWD" | grep "$FS" > /dev/null 2>&1 && grep -i Fedora < /etc/os-release > /dev/null 2>&1 ; then
		 szsh
	elif echo "$PWD" | grep "$ARS" > /dev/null 2>&1 && grep -i Arch < /etc/os-release  > /dev/null 2>&1 ; then
		 szsh
	elif echo "$PWD" | grep "$GS" > /dev/null 2>&1 && grep -i Gentoo < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$DS" > /dev/null 2>&1 && grep -i "Debian\|Ubuntu" < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$VS" > /dev/null 2>&1 && grep -i Void < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$OSS" > /dev/null 2>&1 && grep -i openSUSE < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$NS" > /dev/null 2>&1 && grep -i NixOS < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$PLS" > /dev/null 2>&1 && grep -i PCLinuxOS < /etc/os-release > /dev/null 2>&1; then
		 szsh
	elif echo "$PWD" | grep "$CS" > /dev/null 2>&1 && grep -i CentOS < /etc/os-release > /dev/null 2>&1; then
		 szsh
	fi
}

# Estimate the size of the current repo
# Taken from http://stackoverflow.com/a/16163608/1876983
function gitsize {
	git gc
	git count-objects -vH
}

# Git shrink
# Taken from http://stackoverflow.com/a/2116892/1876983
function gitsh {
	git reflog expire --all --expire=now
	git gc --prune=now --aggressive
}

function pushss {
	push "$1" && gitsh && gitsize
}

# Complete push
function pushf {
	if printf "$PWD" | grep 'AUR' > /dev/null 2>&1 ; then
		mksrcinfo
	fi

	if echo "$PWD" | grep opendesktop > /dev/null 2>&1 ; then
		commc=$(git rev-list --branches master --count)
		commn=$(octave_evaluate "$commc+1")
		sed -i -e "s/PKGVER=[0-9]*/PKGVER=${commn}/g" "$PK"/opendesktop-app/pkg/appimage/appimagebuild
		pushmf "$1"
	elif echo "$PWD" | grep OpenRA > /dev/null 2>&1 ; then
		commc=$(git rev-list --branches bleed --count)
		commn=$(octave_evaluate "$commc+1")
		sed -i -e "s/COMNO=[0-9]*/COMNO=${commn}/g" "$PK"/OpenRA/packaging/linux/buildpackage.sh
		pushmf "$1"
	else
		pushmf "$1"
	fi

	if echo "$PWD" | grep "$HOME/Shell" > /dev/null 2>&1 ; then
		szsh
	elif echo "$PWD" | grep "$FS" > /dev/null 2>&1 && grep -i Fedora < /etc/os-release > /dev/null 2>&1 ; then
		szsh
	elif echo "$PWD" | grep "$ARS" > /dev/null 2>&1 && grep -i Arch < /etc/os-release  > /dev/null 2>&1 ; then
		szsh
	elif echo "$PWD" | grep "$GS" > /dev/null 2>&1 && grep -i Gentoo < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$DS" > /dev/null 2>&1 && grep -i "Debian\|Ubuntu" < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$VS" > /dev/null 2>&1 && grep -i Void < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$OSS" > /dev/null 2>&1 && grep -i openSUSE < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$NS" > /dev/null 2>&1 && grep -i NixOS < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$PLS" > /dev/null 2>&1 && grep -i PCLinuxOS < /etc/os-release > /dev/null 2>&1; then
		szsh
	elif echo "$PWD" | grep "$CS" > /dev/null 2>&1 && grep -i CentOS < /etc/os-release > /dev/null 2>&1; then
		szsh
	fi

	# Update common-scripts dirs
	if echo "$PWD" | grep "$HOME/Shell/common-scripts" > /dev/null 2>&1; then
		if ! echo "$SHELL" | grep zsh > /dev/null 2>&1; then
			read -p "Do you want to update common-scripts submodules and the main common-scripts repo (if not already up-to-date) now? [y/n] " yn
		else
			read "yn?Do you want to update common-scripts submodules and the main common-scripts repo (if not already up-to-date) now? [y/n] "
		fi

		case $yn in
			[Yy]* ) update-common;;
			[Nn]* ) printf "%s\n" "OK, it's your funeral. Run update-common if you change your mind." ;;
			* ) printf "%s\n" "Please answer y or n." ; ...
		esac
	fi
}

function git-changed-list {
	git diff --name-only | awk '
{
    files[NR] = $0
}
END {
    for (i = 1; i <= NR; i++) {
        if (i == 1 && NR == 1)
            printf "%s", files[i]
        else if (i == NR)
            printf " and %s", files[i]
        else if (i == 1)
            printf "%s", files[i]
        else
            printf ", %s", files[i]
    }
    print ""
}'
}


