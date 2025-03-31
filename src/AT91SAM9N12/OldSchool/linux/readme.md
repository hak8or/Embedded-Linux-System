### Getting started
Config file *not* included, so do a menuconf to do any required changes (none are needed), and then run the approriate make commands:
```
make ARCH=arm at91sam9n12ek_defconfig
make ARCH=arm menuconfig
make ARCH=arm CROSS_COMPILE="put crosscompiler path here"
mkimage -A arm -O linux -C none -T kernel -a 20008000 -e 20008000 -n linux-2.6 -d arch/arm/boot/zImage uImage.bin
```

Put the resulting uimage.bin into the primary partition of the USB flash drive.

The [linux4sam linux page](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page#Linux_Kernel) is a good resource for more help if needed.

### Dependancies
- **Cross-Compiler:** Generate using Crosstools-NG (reccomended since you will have to make a cross-compiler eventually) or download from ARM's launchpad [here](https://launchpad.net/gcc-arm-embedded).

- **Linux Kernel:** There are a good bit of required changes by atmel in the form of a patch to a very old ```2.6.39``` kernel, so upgrading to a more modern one is not very possible currently.
```
$ wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.39.tar.bz2
$ tar xvjf linux-2.6.39.tar.bz2
$ cd linux-2.6.39
```

- **Linux Kernel patch:** Atmel require some patches before doing anything, which can handled by doing the following:
```
wget ftp://ftp.linux4sam.org/pub/linux/2.6.39-at91/2.6.39-at91sam9n12-exp.tar.gz
tar xf 2.6.39-at91sam9n12-exp.tar.gz
patch -p1 < u-boot-9n12_m2.patch
...
patch -p1 < last_patch_file.path
```
