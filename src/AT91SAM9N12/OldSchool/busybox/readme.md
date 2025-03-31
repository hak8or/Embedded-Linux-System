### Getting started
Config file already included, so just running applying the patches and then running ```make arch=ARM CROSS_COMPILE="put crosscompiler path here"``` should suffice. You can do make ```make menuconfig``` to select if you want it to be statically or dynamically linked. If dynamically linked, you need to add the approriate librares from your cross compilers ```sysroot/lib``` directory.

Busybox makes it's own inittab if one isn't provided, but it assumes that there are more serial ports than there really are, causing it to spam the serial port with ```/dev/ttyS# missing``` messeges every ~1/4 of a second. Supplying your own like this will prevent that.
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
Check the [root_file_sys directory](root_file_sys/) for more detail and a script which does this for you. Also, [this](https://gist.github.com/eepp/6056325) amazing gist shows how to handle a rootfs with busybox, and while it's for the beaglebone the process is nearly indentical for sam9n12 after the kernel steps.

If using a staticly compile busybox then there are no needed shared libraries to copy.
- **Simple:** Just putting the executable in the rootfs at /bin and calling busybox *command*
- **Correct:** Run ```make install``` which makes a _install dir containing approriate symlinks, allowing you to run commands normally.

### Dependancies
- **Cross-Compiler:** Generate using Crosstools-NG (reccomended since you will have to make a cross-compiler eventually) or download from ARM's launchpad [here](https://launchpad.net/gcc-arm-embedded).

- **Busybox:** You can get the official most recent source from the official repo like so ```git clone git://busybox.net/busybox.git```. No modifications are needed.
