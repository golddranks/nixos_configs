#!/bin/bash

booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
built="$(readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"

printf "System booted with:\n%s\n" "$booted"
echo
printf "Current build is:\n%s\n" "$built"
echo

if [ "$booted" != "$built" ]; then
	echo "They are different, so you should perhaps reboot."
else
	echo "No differences!"
fi
