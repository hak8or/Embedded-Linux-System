# zImage minifying

## Measurements

As shown earlier, we have a ```2.7 MB``` zImage (kerenel image) when our size limit is ```1.846 MB```, and our root file system is ```1.2 MB``` which is under the max of ```2.217 MB```. There are two points of confusion here:

- Why is the root file system so large? It should only have busybox with ```libc``` and ```libc++``` which when combined shouldn't be over a megabyte.
- What can we remove from the zImage to get the kernel size down while still have a decently functional system?

Lets look at the root file system first since Buildroot provides ```make graph-size```. This will let us see what is occupying so much space in our rootfs via nice plots and csv files in the ```output/graphs``` folder. Keep in mind that "Total filesystem size" is the uncompressed version, meaning no compression has been applied. After pumping the root filesystem through squashfs and then compressing it with xz it drops from ```3.5 MB``` down to ```1.2 MB```.

![Root File System](images/RootFS_Size0.PNG)

Hm, that is unusual, what the heck is "Linux"? The kernel isn't in the root file system (it's put in a totally separate area in data flash). Unknown is also worth looking into. Thankfully Buildroot also generates a file called ```file-size-stats.csv```. The contents help give us more information, of which a trimmed version is below.

```none
[hak8or@hak8or graphs]$ cat file-size-stats.csv | awk '{gsub("lib/modules/4.15.7/kernel/drivers/", "..."); print}' | column -s, -t | grep -v " 4096 " | sort -n -k 3 | tail -n 10
File name                                                    Package name          File size  Package size  File size in package (%)  File size in system (%)
...net/wireless/realtek/rtlwifi/rtl8192c/rtl8192c-common.ko  linux                 48268      1130774       4.3                       1.3
...net/wireless/ralink/rt2x00/rt2x00lib.ko                   linux                 48736      1130774       4.3                       1.3
...net/wireless/ralink/rt2x00/rt2800usb.ko                   linux                 49804      1130774       4.4                       1.4
...net/wireless/marvell/libertas/libertas.ko                 linux                 65316      1130774       5.8                       1.8
...net/wireless/realtek/rtlwifi/rtlwifi.ko                   linux                 75804      1130774       6.7                       2.1
...net/wireless/realtek/rtlwifi/rtl8192cu/rtl8192cu.ko       linux                 82528      1130774       7.3                       2.3
...net/wireless/ralink/rt2x00/rt2800lib.ko                   linux                 96488      1130774       8.5                       2.7
...net/wireless/marvell/mwifiex/mwifiex.ko                   linux                 275384     1130774       24.4                      7.6
lib/libuClibc-1.0.28.so                                      uclibc                489384     562728        87.0                      13.5
bin/busybox                                                  busybox               719316     722918        99.5                      19.9
```

This tells us that a decent portion of the files seem to be device drivers for various USB based wireless dongles, and they all come from the Linux package.

## Kernel

The Linux kernel is a monolithic kernel, meaning the entire Operating System is running in kernel space, including various device drivers. Therefore, device drivers tend to be included in the kernel source code, in our case being the USB wireless dongles, hence these drivers being marked as coming from the "Linux" package. [Here](https://elinux.org/Kernel_Size_Tuning_Guide) is a great guide on how to measure and tune the size of the kernel, some of which we will be using here. When compiling the Linux kernel you can specify if you want various components to be compiled into the image (zImage in our case) or as "Modules" which get loaded at run time from the root file system. For example, in the below image of the kernel configuration, the "Marvel WiFi-Ex" drivers are compiled as modules while the "Realtek rtlwifi" drivers are compiled into the kernel image. This is why you see the Marvel drivers in the above snippet, since they are in the root file system instead of the kernel image.

![Kernel Modules vs inimage](images/Buildroot_Kernel_Module.PNG)

Buildroot lets you access various packages (one of which is Linux) through the make tool in the format of ```make *packagename*-make/menuconfig/nconfig/clean/rebuild```. For example, to view the menuconfig of the Linux kernel using nconfig, then you should use ```make linux-nconfig```. Looking around in there, we can see there are many options which are enabled, such as networking and these device drivers.

As a reminder, our goal is to have our system do the following:

- Boot to a shell and be able to communicate with it over serial
- Networking support
- Use the [RNX-N150HG](https://wikidevi.com/wiki/Rosewill_RNX-N150HG) USB Wifi dongle to talk to the outside world
- Read only file system with compression (SquashFS)
- Run various tools (htop, stress, tmux, ping)
- If possible, an ssh server and [TCC](https://www.wikiwand.com/en/Tiny_C_Compiler) to compile a small C based demo program

Things we do not need:

- Video output (no Xorg or VGA or DVI)
- Audio output (no I2S)
- Any file system other than SquashFS

### Non Relevant Wireless USB drivers

We only need to support the Atheros ```AR9002U``` chipset and Atheros ```AR9271```wireless chip. The driver for this is called **ath9k_htc Drivers** according to the [wikidev](https://wikidevi.com/wiki/Rosewill_RNX-N150HG) site. It is not clear on what this driver is listed under in the kernel configratuion, so simply searching for symbols with "ath9k" when using the nconfig viewer gives this.

![ATH9k Search](images/Linux_ath9k_search.PNG)

This tells us we need to go into ```Device Drivers -> Network device Support -> Wireless LAN``` and enable the ```Atheros/Qualcomm devices``` node to enable the ```ATH9k``` driver. This is a general driver for the Atheros and Qualcomm interface though, not the specific chipset we are using. If I can't find the information I need via a symbol search then usually searching the [kernel mirror](https://github.com/torvalds/linux) on Github will give what you need. In our case, searching for the ```AR9271``` keyword in the repository gives us [this](https://github.com/torvalds/linux/blob/b2fe5fa68642860e7de76167c3111623aa0d5de1/drivers/net/wireless/ath/ath9k/Kconfig#L169), showing that we also need to enable ```ATH9k_HTC```. If we enable these two components and disable all other entries in ```Wireless LAN``` then the size of the zImage is still ```2.7MB``` but the compressed rootfs is only ```848KB```, which is a savings of ```380KB``` compared to the previous ```1.2MB```!

### Non Relevant kernel modules

While our root file system dropped to satisfactory levels, our kernel image is still far too large. Here is a chart showing all the kernel functionality which can be removed while still being able to satisfy our intended functionality.

| Component Name | zImage size in kB |
| :------------- | :---------------- |
| Graphics support (DRM, backlight, logo, framebuffer) | 169 kB |
| ext4 in Fle Systems | 138 kB |
| Network FIle Systems in File systems | 112 kB |
| Atheros and HTC driver as Module (+116 kB to RootFS) | 94 kB |
| Atheros and HTC driver as in Kernel | 91 kB |
| soundcard support | 84 kB |
| Miscellaneous file systems (UBIFS) in File systems | 77 kB |
| Multimedia support | 62 kB |
| SCSI device support | 56 kB |
| MMC SD SDIO card support | 46 kB |
| Enable Stack unwinding support | 39 kB |
| UBI Support | 32 kB |
| NAND device support in Memory Technology Device (MTD) support | 28.5 KB |
| USB Gadget | 28 kB |
| HID | 27.8 kB |
| vfat in DOS/FAT/NT file systems | 20 kB |
| Industrial IO support | 19 kB |
| Suspend to RAM and standby | 16.6 kB |
| Ethernet Driver in Network device support | 15 kB |
| Initial RAM disk/file system | 14.5 kB |
| EHCI HCD | 14.4 kB |
| Voltage and current regulator support | 14 kB |
| PHY Device support in Network Device Support | 13 kB |
| I2C Support | 12.8 kB |
| Real Time Clock | 11.5 kB |
| all input device support | 11 kB |
| USB Serial Converter | 11 kB |
| SquashFS with only XZ (removed other compression) | 6.7 kB |
| PPS + PTP | 5 kB |
| PWM Support | 5 kB |
| USB Modem (CDC ACM) | 5 kB |
| Watchdog timer support | 3.7 kB |
| Power supply class support | 3.5 kB |
| NVMEM | 2.3 kB |
| Board level reset or power off | 2kB |
| Atmel HLCDC (High-end LCD Controller) | 1.7 kB |
| MDIO Bus Device Drivers | 1.5 kB |
| Atmel SOC AT91RM9200 | 1 kB |
| Verbose user fault messages | 0.5 kB |

After removing all of these and having the WiFi drivers in the kernel instead of as modules, we have a file size as follows;

```bash
[hak8or@CT108 buildroot-2018.02.1]$ ls -la --block-size=k output/images/
total 2673K
drwxr-xr-x 2 hak8or hak8or    1K May  2 05:00 .
drwxr-xr-x 6 hak8or hak8or    1K May  2 03:25 ..
-rw-r--r-- 1 hak8or hak8or   18K May  2 05:00 at91sam9n12ek_custom.dtb
-rw-r--r-- 1 hak8or hak8or  844K May  2 05:00 rootfs.squashfs
-rw-r--r-- 1 hak8or hak8or 1748K May  2 05:00 zImage
```

## What's else

When the kernel gets compiled many object files (with a ```.o``` extension) get generated. These are files which get put linked into the kernel image during the compilation process. We can use these files to get a rough estimate of what's taking up space. The zImage is well below our limit, so we do not need to change anything here, this is just for curiosity's sake. As we can see, a large portion of this is networking related (ipv4 and ipv6 stack), and some are various drivers used for wifi.

```none
[hak8or@hak8or build]$ size */built-in.o | sort -n -r -k 4 | head -n 30
 102937      93    1040  104070   19686 linux-4.15.7/net/wireless/nl80211.o (ex linux-4.15.7/built-in.o)
  47725    1529     492   49746    c252 linux-4.15.7/net/core/dev.o (ex linux-4.15.7/built-in.o)
  15770     216   28056   44042    ac0a linux-4.15.7/kernel/printk/printk.o (ex linux-4.15.7/built-in.o)
  41269     536    1176   42981    a7e5 linux-4.15.7/net/ipv6/addrconf.o (ex linux-4.15.7/built-in.o)
  36370      13       8   36391    8e27 linux-4.15.7/net/ipv4/tcp_input.o (ex linux-4.15.7/built-in.o)
  35840     314       0   36154    8d3a linux-4.15.7/net/core/skbuff.o (ex linux-4.15.7/built-in.o)
  33790      30       0   33820    841c linux-4.15.7/net/mac80211/mlme.o (ex linux-4.15.7/built-in.o)
  28294     287    2128   30709    77f5 linux-4.15.7/drivers/tty/vt/vt.o (ex linux-4.15.7/built-in.o)
  28541     675       1   29217    7221 linux-4.15.7/net/ipv6/route.o (ex linux-4.15.7/built-in.o)
  28037      68    1044   29149    71dd linux-4.15.7/net/core/rtnetlink.o (ex linux-4.15.7/built-in.o)
  28582     156      12   28750    704e linux-4.15.7/drivers/usb/core/hub.o (ex linux-4.15.7/built-in.o)
  27864       9       0   27873    6ce1 linux-4.15.7/net/mac80211/tx.o (ex linux-4.15.7/built-in.o)
  26977     360       0   27337    6ac9 linux-4.15.7/crypto/aes_generic.o (ex linux-4.15.7/built-in.o)
  26657       9       0   26666    682a linux-4.15.7/fs/namei.o (ex linux-4.15.7/built-in.o)
  25811     533       4   26348    66ec linux-4.15.7/net/core/filter.o (ex linux-4.15.7/built-in.o)
  25857     287       2   26146    6622 linux-4.15.7/net/packet/af_packet.o (ex linux-4.15.7/built-in.o)
  26055       0       0   26055    65c7 linux-4.15.7/lib/crc32.o (ex linux-4.15.7/built-in.o)
```

Next up is [fixing](USB.md) an issue with USB seemingly not working.
