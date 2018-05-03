# Replicating

To replicate the build this writeup uses, including the specific version of the kernel (4.15.18) and patches for the USB device, here are various files you need. The output size may change slightly due to the GCC toolchain being used by buildroot changing, since it's only specified to use GCC 7.X instead of a specific GCC. Packages such as htop and whatnot are also not locked to a version, so they too may change in size as time goes on.

It is assumed the base directory for this is ```/home/hak8or```. If this should be modified, then make sure to adjust the absolute paths in the various ```defconfig``` files. There are two versions of the system.

- A "minimal" system which boots into a shell with Musl as the c standard library, recognizes the USB WiFi dongle, and applies patches to the kernel for having the dongle work. Additionally it has wpa_supplicant and the dongle firmware installed so a network connection can be setup.

- A "full" version which is on top of the "minimal" version while including packages like htop, curl, tmux, and others. Root user has a password of "pass" which lets people ssh in as the root user.

Both of these versions sit under their own "minimal" or "full" folder. This replication guide will assume the "minimal" version.

## Dependencies

```bash
# Enter the base directory
cd /home/hak8or

# Get buildroot
wget https://buildroot.org/downloads/buildroot-2018.02.1.tar.gz
tar -xzf buildroot-2018.02.1.tar.gz

# Get the buildroot configuration file for the minimal system. To get the full system, just use BrainyV2_buildroot_full_defconfig instead.
wget https://brainyv2.hak8or.com/AT91SAM9N12/configs/BrainyV2_buildroot_minimal_defconfig

# Get the linux configuration file
wget https://brainyv2.hak8or.com/AT91SAM9N12/configs/BrainyV2_kernel_defconfig

# Get the device tree
wget https://brainyv2.hak8or.com/AT91SAM9N12/configs/BrainyV2.dts

# Get the patch for USB clock being wrong.
wget https://brainyv2.hak8or.com/AT91SAM9N12/configs/clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch

# Get the patch for USB bogus pipe error.
wget https://brainyv2.hak8or.com/AT91SAM9N12/configs/USB-Bogus-Pipe-warning-rate-limited.patch
```

## Running

```bash
# Enter buildroot dir
cd buildroot-2018.02.1

# Copy over the defconfig
make defconfig BR2_DEFCONFIG=/home/hak8or/BrainyV2_buildroot_minimal_defconfig

# Build our system!
make
```

Then to build this, a simple ```make``` in the buildroot folder should suffice. The buildroot defconfig should pull in the device tree, apply the USB clock patch, and compile the kernel with the custom defconfig. The output should be in ```output/images```. If you have issues, ensure the paths in the various ```defconfig```'s is accurate.

## Output size

```bash
[hak8or@CT108 buildroot-minimal]$ ls -la --block-size=k output/images/
total 3234K
drwxr-xr-x 2 hak8or hak8or    1K May  3 04:58 .
drwxr-xr-x 6 hak8or hak8or    1K May  3 04:39 ..
-rw-r--r-- 1 hak8or hak8or   18K May  3 04:58 BrainyV2.dtb
-rw-r--r-- 1 hak8or hak8or 1408K May  3 05:14 rootfs.squashfs
-rw-r--r-- 1 hak8or hak8or 1749K May  3 04:58 zImage

[hak8or@CT108 buildroot-minimal]$ cd ../buildroot_full


[hak8or@CT108 buildroot_full]$ ls -la --block-size=k output/images/
total 4015K
drwxr-xr-x 2 hak8or hak8or    1K May  3 18:52 .
drwxr-xr-x 6 hak8or hak8or    1K May  3 18:16 ..
-rw-r--r-- 1 hak8or hak8or   18K May  3 18:51 BrainyV2.dtb
-rw-r--r-- 1 hak8or hak8or 2200K May  3 18:52 rootfs.squashfs
-rw-r--r-- 1 hak8or hak8or 1749K May  3 18:51 zImage
```

## New defconfig

Most packages in buildroot, including buildroot itself, have the ability to save their menuconfig state via a ```make {pkg_name}_savedefconfig``` command. Buildroot itself is a bit diffirent, for example doing ```make savedefconfig``` doesn't seem to create a defconfig file anywhere. Instead, doing ```make savedefconfig BR2_DEFCONFIG=defconfig``` creates a defconfig file at the root of the buildroot directory.

On the other hand, saving the Linux configuration can be done by ```make linux-savedefconfig``` with the file created in ```output/build/linux-4.15.18/defconfig```.