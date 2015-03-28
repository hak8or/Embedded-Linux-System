# Atmel SAM9N12 Embedded Linux System

### Getting started
Right now, you have to manually find and download all the needed dependancies. A script will hopefully be written someday to automate downloading and patching all the files.

Use the Atmel SAM9N12 [linux4sam](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page) page for a general overview of the build process.

### Status
NAND flash doesn't work for some reason (probably thermally damaged it when using my garbage desoldering braid), so dataflash is used instead. The dataflash chip is attached to the SPI bus from the chip to the SPI bus pads while also using it's own board. DRAM is also underclocked to 100 Mhz instead of 133 Mhz, causing the processor to run at 300 Mhz instead of 400 Mhz. AT91 Bootstrap and U-Boot are located on dataflash at ```0x00``` and ```0x8400``` respectivly, with U-Boot pulling the kernel from a flash drive connected via USB OTG as well. The kernel then pulls the rootfs off the flash drive in a dedicated ext2 rootfs as rw. GCC has been cross compiled to this board and compiles programs correctly, so this board was used for completion of the project.

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

### Resources blob from OneTab
- [LegacySAM9N12Page < Linux4SAM < TWiki](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page#Linux_Kernel)
- [Booting The Linux Kernel | STLinux](http://www.stlinux.com/?q=node/119/#RAMDiskBoot)
- [UBootEnvVariables < DULG < DENX](http://www.denx.de/wiki/view/DULG/UBootEnvVariables)
- [Booting The Linux Kernel | STLinux](http://www.stlinux.com/u-boot/kernel-booting)
- [bootloaders:u-boot:usb Analog Devices Open Source | Mixed-signal and Digital Signal Processing ICs](http://blackfin.uclinux.org/doku.php?id=bootloaders:u-boot:usb)
- [A Handy U-Boot Trick | Linux Journal](http://www.linuxjournal.com/content/handy-u-boot-trick)
- [KernelBuild - Linux Kernel Newbies](http://kernelnewbies.org/KernelBuild)
- [Ttl/sam_board](https://github.com/Ttl/sam_board)
- [sam_board/sam_board.patch at master · Ttl/sam_board](https://github.com/Ttl/sam_board/blob/master/software/at91bootstrap/sam_board.patch)
- [U-Boot < Linux4SAM < TWiki](http://www.at91.com/linux4sam/bin/view/Linux4SAM/U-Boot)
- [LegacyU-Boot < Linux4SAM < TWiki](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacyU-Boot#DataFlash)
- [AT91Bootstrap < Linux4SAM < TWiki](http://www.at91.com/linux4sam/bin/view/Linux4SAM/AT91Bootstrap#Boot_capabilities_matrix)
- [LegacySAM9N12Page < Linux4SAM < TWiki](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page)
- [Aria G25 256MB boot problem - Google Groups](https://groups.google.com/forum/#!topic/acmesystems/NeXjxqVJZcU)
- [Building U-Boot and Linux 3.11 from scratch for the BeagleBone, and booting](https://gist.github.com/eepp/6056325)
- [MT46V32M16P-5B:J - Micron Technology, DRAM Chip. Order from Arrow Electronics.](http://parts.arrow.com/item/detail/micron-technology/mt46v32m16p-5bj#Qncy)
- [Sourcery CodeBench Lite 2014.05-29 for ARM GNU/Linux](https://sourcery.mentor.com/GNUToolchain/release2795?)
- [Gentoo Forums :: View topic - VFS: Cannot open root device "sda2" or unknown-block(0,0) ..](http://forums.gentoo.org/viewtopic-p-6384064.html?sid=8e84f81ab9bbf668c2eefb6b9a4266a0)
- [0x6: Root file system for embedded system - Linux geek's scratchpad](http://pietrushnic.github.io/blog/2013/06/07/root-file-system-for-embedded-system/)
- [busybox Inittab](http://git.busybox.net/busybox/tree/examples/inittab)
- [BusyBox - The Swiss Army Knife of Embedded Linux](http://www.busybox.net/downloads/BusyBox.html)
- [How do I check busybox version (from busybox)? - Unix & Linux Stack Exchange](http://unix.stackexchange.com/questions/15895/how-do-i-check-busybox-version-from-busybox)
- [android - How to compile Busybox? - Stack Overflow](http://stackoverflow.com/questions/22409516/how-to-compile-busybox)
- [BusyBox simplifies embedded Linux systems](http://www.ibm.com/developerworks/library/l-busybox/)
- [Cross Compiling BusyBox for ARM - BeyondLogic](http://wiki.beyondlogic.org/index.php?title=Cross_Compiling_BusyBox_for_ARM)
- [Re: [patches] Cross-building instructions](http://www.eglibc.org/archives/patches/msg00078.html)
- [How to Build a GCC Cross-Compiler](http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/)
- [How To Cross-Compile Clang/LLVM using Clang/LLVM — LLVM 3.7 documentation](http://llvm.org/docs/HowToCrossCompileLLVM.html)
- [Cross-Compiling for the Raspberry Pi](https://mborgerson.com/cross-compiling-for-the-raspberry-pi/)
- [Bryan Hundven - Re: Cross compile native gcc for arm with crosstool-ng, have toolchain,](https://sourceware.org/ml/crossgcc/2012-11/msg00016.html)
- [Linux in Android! DesirAPT is at Beta Test! - Post #5 - XDA Forums](http://forum.xda-developers.com/showpost.php?p=18356849&postcount=5)
- [Crosstool-NG](http://crosstool-ng.org/)
- [crosstool-ng/1 - Introduction.txt at master · crosstool-ng/crosstool-ng](https://github.com/crosstool-ng/crosstool-ng/blob/master/docs/1%20-%20Introduction.txt)
- [dayid's screen and tmux cheat sheet](http://www.dayid.org/os/notes/tm.html)
- [enable multithreading to use std::thread: operation not permitted arm at DuckDuckGo](https://duckduckgo.com/?q=enable+multithreading+to+use+std%3A%3Athread%3A+operation+not+permitted+arm&t=ffsb)
- [multithreading - C++ Threads, std::system_error - operation not permitted? - Stack Overflow](http://stackoverflow.com/questions/17274032/c-threads-stdsystem-error-operation-not-permitted)
- [c++ - version `CXXABI_1.3.8' not found (required by ...) - Stack Overflow](http://stackoverflow.com/questions/23494103/version-cxxabi-1-3-8-not-found-required-by)
- [embedded linux - When we build a kernel and busy box, we need toolchain only for busybox not for kernel? - Stack Overflow](http://stackoverflow.com/questions/17785208/when-we-build-a-kernel-and-busy-box-we-need-toolchain-only-for-busybox-not-for)