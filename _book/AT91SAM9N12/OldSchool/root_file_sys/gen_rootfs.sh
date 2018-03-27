#!/bin/bash

# Resources:
#	http://pietrushnic.github.io/blog/2013/06/07/root-file-system-for-embedded-system/
#	https://gist.github.com/eepp/6056325

# Arguments:
#	none       Compile busybox, make a rootfs from busybox and rootfs_additions, and get an ext2 fs from rootfs.
#   make_ext2  Just make an ext2 from the rootfs folder.
#   write_usb  Same as none but also write the rootfs to a flash drive.

# Allow the script to just remake the filesystem.
if [[ $1 = "make_ext2" ]]; then
	make_ext2_fs

	exit
fi

# Make an ext2 root filesystem image.
make_ext2_fs() {
	echo -n "Making an ext2 rootfs called rootfs.ext2 ... "
	# Make a 20 MB empty file to hold the image
	dd if=/dev/zero of=../rootfs.ext2 bs=1M count=500

	# Make that file use an ext2 FS.
	mkfs.ext2 ../rootfs.ext2

	# Make a dir for mounting the rootfs image too
	rm -r -f ../rootfs_ext2_mountpoint
	mkdir ../rootfs_ext2_mountpoint

	# Mount the rootfs to that point.
	mount ../rootfs.ext2 ../rootfs_ext2_mountpoint

	# Copy all the stuff from the rootfs folder.
	cp -a ../rootfs/* ../rootfs_ext2_mountpoint

	# Unmount
	umount ../rootfs_ext2_mountpoint

	echo "OK"
}

# Delete the _install dir if it exists to make sure we have a clean slate.
if [ -d _install ]; then
	echo -n "Wiping _install ..."
    rm -r -f _install
    echo "OK"
fi

# Delete the rootfs dir if it exists to make sure we have a clean slate.
if [ -d ../rootfs ]; then
	echo -n "Wiping ../rootfs ..."
    rm -r -f ../rootfs
    echo "OK"
fi

# Compile busybox and setup symlinking. Seems that make install recompiles busybox if it doesn't exist in _install.
make ARCH=arm CROSS_COMPILE=/home/hak8or/Desktop/sam9n12/toolchain_codesourcery/arm-2014.05/bin/arm-none-linux-gnueabi- install -j3

# Make the rootfs dir.
mkdir -p ../rootfs

# Copy busybox's entire rootfs including all the symlinks over to our rootfs.
cp -a _install/* ../rootfs/

# ==========================================================
# ==========================================================
#             Non busybox mods to the roofs
# ==========================================================
# ==========================================================
# We need the libraries from the toolchain like libc and libstdc++ for dynamic linking.
# Put them in /lib and /usr/lib. Get rid of the locals folder, it's massive and not needed.
#
# The libs can be found in these places in the toolchains sysroot folder.

# Make sure the dir exists to hold stuff we want to manually add to the rootfs
mkdir -p ../rootfs_additions

# And copy everything from the dir where we hold manually added stuff.
cp -a  ../rootfs_additions/* ../rootfs

# Make the base dirs of the root file system. The -p creates dirs where needed.
mkdir -p ../rootfs/bin ../rootfs/dev ../rootfs/proc ../rootfs/sys ../rootfs/etc/init.d

# Gives us a file system running from flash, and a file system running from ram.
mkdir -p ../rootfs/mnt/flashfs ../rootfs/mnt/ramfs

# And where we will store content for the user.
mkdir -p ../rootfs/usr/home/hello_world

# A short hello world for the user.
touch ../rootfs/usr/home/hello_world/hello.cpp
cat <<'EOF' >> ../rootfs/usr/home/hello_world/hello.cpp
#include <iostream>

int main(void) { 
	std::cout << "Hello world!\n";
	return 0;
}
EOF

# Make a few important nodes. The numbers are associated with sym-links inside /sys/dev/char/
mknod ../rootfs/dev/console c 5 1
mknod ../rootfs/dev/null c 1 3
mknod ../rootfs/dev/ttyAMA0 c 204 64
mknod ../rootfs/dev/zero c 1 5

# Makes an initab file to handle booting.
touch ../rootfs/etc/inittab
cat <<'EOF' >> ../rootfs/etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF

# And an init.d/rcS
touch ../rootfs/etc/init.d/rcS
cat <<'EOF' >> ../rootfs/etc/init.d/rcS
#! /bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# Writable mount points.
mount -t ramfs -o size=5m ramfs /mnt/ramfs -w
EOF
chmod +x ../rootfs/etc/init.d/rcS

# And add in an init manually. 
# Check if we still need to do this or if busybox install does this for us.
ln -s busybox ../rootfs/bin/init

# Generate a root filesystem ext2 based image. Commented out since we
# aren't using this currently. This will be later used for a JIFFS or
# cramfs or whatever type of FS on flash.
# make_ext2_fs

# Copy the rootfs over to our flash drive.
if [[ $1 = "write_usb" ]]; then
	echo -n "Copying to flash drive ... "

	# Wipe whatever was on the flash drive to make sure everything is clean
	rm -r -f /media/hak8or/95ba7c1e-6ecc-4bd4-9519-4d7e05c7e0fe/*; sync

	# Copy the rootfs over to our flash drive and sync to make sure it was writte too.
	cp -a ../rootfs/* /media/hak8or/95ba7c1e-6ecc-4bd4-9519-4d7e05c7e0fe/; sync

	echo "OK"
fi

# And say we are done.
echo "And we are done :D"
