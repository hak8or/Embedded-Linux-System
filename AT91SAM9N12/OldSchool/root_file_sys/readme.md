### Getting started
The rootfs is relativly simple to setup depending on how much you functionality you want.

Also, [this](https://gist.github.com/eepp/6056325) amazing gist shows how to handle a rootfs with busybox, and while it's for the beaglebone the process is nearly indentical for sam9n12 after the kernel steps.

#### Just Busybox
If all you want is busybox and nothing else, then :
- statically compile busybox and run a ```make install```
- Copy the contents of busybox's _install into rootfs_additions using ```cp -a```, the ```-a``` flag also copies the required symlinks
- Make a few device nodes
```
mknod rootfs/dev/console c 5 1
mknod rootfs/dev/null c 1 3
mknod rootfs/dev/ttyAMA0 c 204 64
```
- Make an inittab to prevent the ttyS# spam in the terminal.
```
touch rootfs/etc/inittab
cat <<'EOF' >> rootfs/etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF
```
- Make an rcS: ```touch rootfs/etc/init.d/rcS && chmod +x rootfs/etc/init.d/rcS```

#### Busybux + other applications
If you plan on adding other applications, do as above but don't comple busybox statically. Then also copy the contents of the rootfs dir from your cross compiler and add your aplications to somewhere like ```/usr/home/cross_compiled_bin/```. If you will use dynamic linking for your applications and not use normal libraries in normal locations, then add the new library locations to ```/etc/ld.so.conf``` so the kernels dynamic linker can see them.

#### Busybux + other applications + gcc
If you want to also add gcc, then all you need to do in addition to above is just copy the gcc base dir such as ```arm-none-linux-gnueabi``` to someplace like ```/usr/home/toolchain/```. Compiling things just requires calling ```arm-none-linux-gnueabi-g++ file.cpp``` like normal gcc operations. Make sure to remove ```locales``` since we don't need them and they take up a monsterous 150MB+.

Assuming gcc is in ```/usr/home/toolchain/```, then you can add a symlink of g++ into ```/bin``` by doing the following which lets you compile by doing ```g++ main.cpp```:

```symlink /bin/g++ /usr/home/toolchain/arm-none-linux-gnueabi/bin/arm-none-linux-gnueabi-g++``` 

#### Script
There is a script which will do all of what is above automatically for you:
- Compile busybox.
- Copy the contents of the busybox _install dir into the rootfs.
- Make a hello world source file in ```/usr/home/hello_world/```.
- Generate device nodes such as ```/dev/zero``` and ```/dev/ttyACM0```.
- Generate an ```inittab``` which prevent the ttyS# spam in the terminal.
- Generate an ```rcS``` which gets the kernel to populate ```/sys``` and ```/proc``` dir's and make a 5MB ramfs in /ramfs.
- Combine the rootfs_additions folder into the roofs.
- Optionally make an ext2 based image of the rootfs.
- Optionally write the rootfs into the correct partition of the USB flash drive.

This script needs to be run under sudo currently, so ```sudo ./gen_rootfs.sh write_usb``` will do the above and write the image to the flash drive.