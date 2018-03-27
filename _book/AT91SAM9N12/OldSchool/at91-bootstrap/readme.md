### Getting started
Config file already included, so just running applying the patches and then running ```make arch=ARM CROSS_COMPILE="put crosscompiler path here"``` should suffice.

Using SAM-BA, dump this to dataflash using the burn bootloader option. **DO NOT** use the save file option, since the burn bootloader option fills in the needed bootloader file length during saving to dataflash used for determinig how much data off dataflash needs to be copied into internal SRAM by the NVM bootloader.

### Targets for config
- ```at91sam9n12ekdf_linux_zimage_dt_defconfig```
- ```at91sam9n12ekdf_linux_uimage_dt_defconfig```
- ```at91sam9n12ekdf_linux_zimage_defconfig```
- ```at91sam9n12ekdf_linux_uimage_defconfig```
- ```at91sam9n12ekdf_uboot_defconfig``` <-- Use this if not using config file.

### Dependancies
- **Cross-Compiler:** Generate using Crosstools-NG (reccomended since you will have to make a cross-compiler eventually) or download from ARM's launchpad [here](https://launchpad.net/gcc-arm-embedded).

- **AT91bootstrap:** The source can be gotten using ```git clone git://github.com/linux4sam/at91bootstrap.git``` but if the you need the old version which is guaranteed to work with this chip, you can get it off the Linux4sam website using the [LegacySAM9N12](http://www.at91.com/linux4sam/bin/view/Linux4SAM/LegacySAM9N12Page) page, prepackged in a [tar archive](ftp://ftp.linux4sam.org/pub/at91bootstrap/AT91Bootstrap3.2/at91bootstrap_9n12.tar.gz). Note, extract the arhive like a pro by doing ```tar xf t91bootstrap_9n12.tar.gz``` which auto determines the archive type.

### Changes outline
- **Memory**
  - **64MB vs 128MB:** The at91sam9n12ek (at91sam9n12 Eval Kit) is designed with 128 MB DRAM, but we are only using 64 MB, which is reflected in ```board/at91sam9n12ek/at91sam9n12ekdf_uboot_defconfig```. 
  - **4 vs 8 Banks + timings:**  My memory is also from another company which means diffirent timings, as well as due to the smaller size less banks (4 vs 8), both of which are reflected in ```board/at91sam9n12ek/at91sam9n12ek.c```. 
  - **100 Mhz vs 133 Mhz:**  The memory clock which is baisically the main system bus clock was dropped from 133 Mhz to 100 Mhz. I didn't get a chance to really test this, just added it while changing the timings due to potential signal integrity issues, so chances are it's not needed. This is reflected in ```board/at91sam9n12ek/at91sam9n12ek.h```. Note, this also drops the core clock from ~400 Mhz to ~300 Mhz.
- **SPI debug**
  - **Debug prompts:** Added debug serial prompts saying the current master clock, requested SPI clock, and the current scbr register state. This is reflected in ```driver/at91_spi.c```.
- **Main program**
  - **Memory tests:** Added memory tests such as alternating patterns, specific patterns, verifying arm exception vectors, and detecting (un)filled memory. These are not all functional tests as of commiting, and will be cleaned up eventually. Reflected in ```main.c```
  - **Debug prompts:** Added debug prompts to indicate bootloader progress. Reflected in ```main.c```

The above changes are in the patch files, apply them sequentially using ```git apply patch-file.patch```.