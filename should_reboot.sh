#!/bin/sh

booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
built="$(readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"

printf "System booted with:\n$booted\n"
echo
printf "Current build is:\n$built\n"

if [ "$booted" != "$built" ]; then
	echo
	echo "They are different, so you should perhaps reboot."
fi
