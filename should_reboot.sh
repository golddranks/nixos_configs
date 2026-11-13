#!/bin/sh

boot_files() {
	readlink "$1/initrd" "$1/kernel" "$1/kernel-modules"
}

booted="$(boot_files /run/booted-system)"
built="$(boot_files /nix/var/nix/profiles/system)"

printf "System booted with:\n%s\n" "$booted"
echo
printf "Current build is:\n%s\n" "$built"
echo

if [ "$booted" != "$built" ]; then
	echo "They are different, so you should perhaps reboot."
else
	echo "No differences!"
fi
