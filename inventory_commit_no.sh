#!/bin/bash
function comno {
    git -C /var/lib/$1-packages rev-list --branches master --count
}
CP=$(comno custom)
if [[ -d /var/lib/book-packages/.git ]]; then
	BP=$(comno book)
	echo "  $BP  $CP"
else
	echo "  $CP"
fi
