#!/bin/bash
cat ~/logs/inventory_commit_no_long.log
function comno {
    git -C /var/lib/$1-packages rev-list --branches master --count
}
CP=$(comno custom)
if [[ -d /var/lib/book-packages/.git ]]; then
	BP=$(comno book)
	echo "Package inventory commit number:  $BP  $CP" > ~/logs/inventory_commit_no_long.log
else
	echo "Package inventory commit: number:  $CP" > ~/logs/inventory_commit_no_long.log
fi
