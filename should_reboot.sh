#!/bin/sh

booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
built="$(readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"

printf "System booted with:\n$booted\n"
echo
printf "Current build is:\n$built\n"
echo

if [ "$booted" != "$built" ]; then
	echo "They are different, so you should perhaps reboot."
else
	echo "No differences!"
fi
