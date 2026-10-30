#!/bin/bash
version=$(zsh -ic "gh_com ad-si/woxi")
source $HOME/lfs-scripts/Shell/00-env.sh
sed -i -e "s|^version=.*|version=$version|g" $LFP/woxi-git/build.sh
