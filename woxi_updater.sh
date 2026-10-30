#!/bin/bash
version=$(zsh -ic "gh_com ad-si/woxi")
sed -i -e "s|^version=.*|version=$version|g" $LFP/woxi-git/build.sh
