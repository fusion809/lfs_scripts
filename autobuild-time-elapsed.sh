#!/bin/zsh
for i in $HOME/lfs-scripts/Shell/0*.sh $HOME/lfs-scripts/Shell/10-*.sh
do
	. "$i"
done
echo "$(cbtime)"
