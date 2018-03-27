# Atmel SAM9N12 Embedded Linux System

![Front](images/DSC_9624_S.jpg)

## Description

The SAM9N12 is a low cost MPU from Atmel (now Microchip) that is capable of running linux. It's based on a 400 MHz ARM926EJ-S core from ARM (very old, a far cry from what you can get in even the cheapest of phones or tablets) and has a 32 bit EBI (External Bus Interface) to work with SDRAM and NAND Flash. Also it can use SPI based FLASH for storing data and supports USB OTG letting you use a USB Flash drive as another data store.

This board has:
* 64 MB of DDR2-SDRAM (W9751G6KB-25-ND)
* 4MB of Dataflash (AT45DB321E-SHF-B)
* USB OTG and USB Device broken out (both only up to 12 Mbps Full Speed)

Originally this project was done years ago relying on forked branches of U-Boot and he Linux kernel from Atmel. While this did work, it meant having to use old non mainlined versions of each project. Later this project was restarted with the intention of using mainline sources for everything and BuildRoot to make things easier. The old version, dubbed "Old School" can be found [here](OldSchool.md), and shows how to do everything **manually**, meaning for example, compiling the linux kernel by hand and how to make a zImage. The old version also has the root filesystem on a USB Flash drive including a native GCC!

This version (not Old School) will show the path of bringing a board like this up from start to finish, such as describing the intended boot flow, how to configure all the software (AT91 Bootstrap, Kernel, Root File System, BuildRoot, etc), show various bugs and issues found in the process (USB OTG was a fun one), how much space various functionality uses, and how to build a semi useful root file system (networking, Tmux, stress, htop, etc).

## Status

Everything seems to work except NAND flash, likely due to soldering issues with the SAM9N12 BGA based package. Because NAND flash isn't working, it was decided to try and stick everything in the 32 Megabit Dataflash (yes, bootloader, kerenel, and root filesystem). USB OTG is used for a Wifi dongle so we get networking support.

## Boot Flow

The AT91SAM9N12 has a bootloader in ROM which can boot from NAND Flash, SPI Flash, and SPI Dataflash, and can even boot directly into the linux kernel (therefore not needing U-Boot). There has been some reverse engineering work done on this [here](http://hobbygenius.co.uk/blog/1622).

The memory setup we will be using is as follows:

    AT45DB321E-SHF-B    32 Mbit ->   4,325,376 Byte or 0x__42_0000 (8192 Pages * 528 Bytes)
    W9751G6KB-25-ND    512 MBit ->  67,108,864 Byte or 0x_400_0000

            Flash                                  Item                   DRAM
    0x000000 <MAX: 0x0026D8>                   AT91 bootstrap    ->    Not Copied
    0x002800 <MAX: 0x004B00>                   Device Tree       ->    0x2100_0000
    0x007300 <MAX: 0x1D8D00 or 1,936,640B>     zImage            ->    0x2200_0000
    0x1E0000 <MAX: 0x237C00 or 2,325,504B>     RootFS            ->    Not Copied
    0x417C00 <MAX: 0x008400>                   Non Volatile      ->    Not Copied/Used

As a rough overview to show in the grand scheme of things how this will look:

1. The bootloader will first look for any boot-able data in SPI Flash, SPI Data Flash, and NAND Flash. In our case, we have the AT91 BootStrap in Dataflash at an offset of zero (start of Dataflash).
2. The [AT91 BootStrap](http://www.at91.com/linux4sam/bin/view/Linux4SAM/AT91Bootstrap) will initialize DRAM and then copy data from DataFlash (in our case the Kernel at an offset of ```0x7300```) into DRAM (at ```0x2200_0000```), and the Device Tree from DataFlash at an offset of ```0x4B00``` to DRAM at ```0x2100_0000```. 
3. Then the bootloader will initialize the environment for the Linux kernel and pass execution to the kernel. 
4. Since the kernel is a zImage (self extracting kernel image), the kernel will uncompress itself, execute itself, read the device tree which was copied to RAM earlier, initialize various drivers based on the device tree entries, and lastly pass execution to whatever is relevant in the root file system.

## First boot

First things first, let's get the board powered up with the dataflash erased. Upon bootup the bootloader in ROM of the SAM9N12 will configure basic clocking and the DBGU serial port on pins ```R5``` and ```R6``` to run at 115200 baud and output the text ```RomBOOT```. If you see this then it means a lot went right, such as power integrity is alright, clocking is OK, the BGA package was soldered well, and of course no magic smoke means no shorts. Next we will look into getting DRAM working, compiling the AT91 BootStrap, flashing the Bootstrap to DataFlash, and getting it to boot.
