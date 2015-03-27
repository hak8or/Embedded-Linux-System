# Atmel SAM9N12 Embedded Linux System

Use the Atmel SAM9N12 [linux4sam](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page) page for a general overview of the build process.

### Boot process
- NVM bootloader: Primary bootloader which searches for executable code via arm exception vectors on NAND and Dataflash and elsewhere except USB
- AT91bootstrap: Secondary bootloader which setups up DRAM looks and puts next executable code into top megabyte of DRAM.
- U-Boot: Third bootloader for getting loading linux kernel off USB into memory and passing proper args.
- Linux Kernel: Indended application, runs the rootfs off USB (no copying into memory).

### Overview
The **NVM bootloader** exists in ROM on the SAM9N12 and is the first thing executed upon powerup. This searches in for possible bootable storage mediums such as NAND, Dataflash, SPI, and others except USB, as well as sets up the serial port. If nothing was found then it starts up SAM-BA, which lets the SAM-BA client on a desktop to issue commands to the SAM9N12 over USB, this is used for writing both AT91 bootstrap and U-Boot to onboard dataflash.

Next up is the **AT91 bootloader** which does pretty much the same as the NVM bootloader but also sets up DRAM. Keep in mind that even if DRAM seems to work via SAM-BA, it does NOT mean that it will work also via the at91 bootloader, memory timings were needed to be modified (relaxed) and clock lowered by 33 Mhz to get DRAM working. This sits in Dataflash at ```0x00``` which in this case is a 8 megabit chip. Some memory testing routines were added to this. Keep in mind that the endianess of this is NOT the same as most x86 systems, nibble swapping is done in the memory testing routines when printing.

**U-Boot** sits in dataflash at ```0x8400``` and sets up USB host, reads the DOS partition table for the first partition (FAT) loads ```uiamge.bin``` which is the kernel into memory at ```0x00```, and lastly passes control to the kernel as well as passing boot arguments which are added via compile time. MDT-tools can be used for passing storage mediums information to the kernel but I didn't use it since it just sucks. Enviroment variables such as boot media can be supplied via a text file on USB but it seems we can't initialize USB before reading this file.

The **linux kernel** does it's magic setting up cache and the MMU and all that jazz, and then loads the root filesystem from USB partition 2 as an ext2 filesystem but ext4 could be used if enabled in the kernel during compilation. The kernel then looks for ```/bin/init``` which baisically tells busybox to call ```/etc/inittab``` that tells the system what to do upon a restart/shutdown/ctrl-alt-del/respawn/sysinit. Sysinit tells to check ```/etc/init.d/rcS``` which handles telling the kernel to fill /proc and /sys. A small 5 megabyte ramfs is also made at this step as per ```rcS```, afterwards the ash shell is started which is a very small alternative to bash while lacking some tools.

### Root filesystem.
**Busybox** is a very awesome tool which lets you combine tools like ls, cat, mount, ln, etc into one executable for memory savings and simplicity. Busybox during ```make install``` makes an _install dir that holds the rootfs containing symbolic links to the single busybox executable, allowing calling these tools normally. The single executable can also just be copied into /bin without any symbolic links (assuming static compilation) with the tools called by doing ```busybox tool```. Busybox can also handle an inittab for you, but it assumes that there are serial ports which aren't there, which spams the serial port every 250 milliseconds saying it didn't find them. Supplying an inittab without those serial port declerations fixes this.

A small 5 megabyte **ram file system** is made via rcS but it isn't needed and is a remenant of when I used to mount the rootfs as read only. You can write to it using dd and whatnot to do rough memory tests or writing quickly changing data without wearing down flash.

**GCC** is included in the rootfs at ```/usr/home/arm-none-linux-gnueabi/``` which has been cross compiled to run on this board, as well as a hello world source file at ```/usr/home/hello-world/```. Compiling the hello world takes a solid 5 or so seconds, a lot more if any sort of optimizations are enabled.

**Libraries** are also included in ```/lib``` which are required by busybox if busybox isn't statically compiled. GCC has it's own copy of these libraries in ```/usr/home/arm-none-linux-gnueabi/arm-none-linux-gnueabi/rootfs/``` which are used during static compilation by GCC as well as for the dynamic linker. Since gcc was not statically compiled, it also uses the libraries in /lib. The libraries to put in /lib should be copied from the gcc cross-compiler's ```rootfs/lib/``` folder.

### Toolchain
**Crosstools-NG** was indespensable for handling all toolchain issues. While ARM do offer their version of GCC on Launchpad which includes pending additions to mainline GCC, it is preferrable to make a custom cross-compiler to select what standard c library to use. Crosstools-NG can properly compile a cross compiler as well as handling the chicken and egg problem with the c library and compiler, but it takes a solid 30 minutes to make a cross-compiler. Then, using a [Canadian Build](https://github.com/crosstool-ng/crosstool-ng/blob/master/docs/6%20-%20Toolchain%20types.txt) (cross-native isn't currently supported), a cross-native compiler is compiled with the target tuple being the previously compiled cross-compiler, which takes roughly 45 minutes. In total, compiling a cross compiler and then a cross-native compiler using a normal build and then canadian build respectivly, takes roughly *an hour and fifteen minutes*.

### Getting started
Right now, you have to manually find and download all the needed dependancies. A script will hopefully be written someday to automate downloading and patching all the files.