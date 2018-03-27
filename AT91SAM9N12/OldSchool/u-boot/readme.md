### Getting started
Config file *not* included, so first apply my patch, do a menuconf to verify memory addresses are correct, and then run the approriate make commands:
```
git apply 0001-Relocating-U-Boot-change-128-to-64MB-USB-boot.patch
make at91sam9n12ek_USB_config
make arch=ARM CROSS_COMPILE="put crosscompiler path here" menuconf
make arch=ARM CROSS_COMPILE="put crosscompiler path here"
```

Using SAM-BA, dump ```uboot.bin``` to dataflash at ```0x8400``` using the the save file option.

The [linux4sam U-Boot page](http://www.at91.com/linux4sam/bin/view/Linux4SAM/U-Boot) is a good resource for more help if needed.

Check ```u-boot.map``` to verify that u-boot is expecting itself in the correct place in memory.

### Targets for config
- ```at91sam9n12ek_mmc```
- ```at91sam9n12ek_nandflash```
- ```at91sam9n12ek_spiflash```
- ```at91sam9n12ek_USB``` <-- Use this if not using config file.

### Dependancies
- **Cross-Compiler:** Generate using Crosstools-NG (reccomended since you will have to make a cross-compiler eventually) or download from ARM's launchpad [here](https://launchpad.net/gcc-arm-embedded).

- **U-Boot:** You can get the new newest U-Boot official source but going to an old git tag is required.
```
git clone http://git.denx.de/u-boot.git
cd u-boot && git checkout v2011.06 -b yourbranch
```
Or an archive already at the correct branch and everything.
```
wget ftp://ftp.denx.de/pub/u-boot/u-boot-2011.06.tar.bz2
tar xf u-boot-2011.06.tar.bz2
```

- **U-Boot patch:** Atmel require a patch to U-Boot before doing anything, which can handled by doing the following:
```
wget ftp://ftp.linux4sam.org/pub/uboot/u-boot-v2011.06/u-boot-9n12_m2.patch
patch -p1 < u-boot-9n12_m2.patch
```

### Changes outline
- **Board configuration**
  - **LCD:** The LCD functionality was disabled to save code size and remove unnecessary pin I/O state changes.
  - **64MB vs 128 MB:** There is only 64 MB of DRAM on my board compared to 128MB on the evel kit.
  - **Memory test:** U-Boot automatically tests memory upon bootup, decreased the region memory is tested to just 128 bytes since we already know memory works correctly, to save boot time, and there is only have as much RAM so this had to change anyways.
  - **U-Boot address (text base):** U-Boot by default is inserted into the last megabyte of DRAM via a hardcoded address, but I decided to stick it in ```0x20008400``` (DRAM memory base is ```0x20000000```) to not keep mixing up with it's location in dataflash which is at ```0x8400```, and because the last megabyte for 64MB of DRAM is diffirant than 128MB. Somehow loading the linux kernel into the memory at it's base doesn't overwrite U-Boot, just noticed. *Whoops*
  - **Sys load address:** Where the kernel gets loaded into, changed from ```0x22000000``` to DRAM base, somehow not crashing U-Boot in the process.
- **Boot options**
  - **USB boot option:** Properly added to ```boards.cfg``` and ```include/configs/at91sam9n12ek.h``` the ability to boot from USB by starting usb, loading the kernel off USB into memory, and starting the kernel with boot arguments to get the rootfs off USB too.

The above changes are in the patch file, apply it using ```git apply patch-file.patch```.
