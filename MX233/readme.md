# Freescale I.MX233 Embedded Linux System

### Status
Currently not working due to issues with DRAM not seeming to be stable. Might have to mess with the timings a good bit more as well as lowering the clock from 133 Mhz to 100 Mhz.

A 22 uF capacitor under the SDHC holder is too tall, causing the SD card to not fully sit in the holder since it can't be closed, so a finger has to be used by pushing the sd card down when in operation.

**NOTE** Don't bother with the BCB (Boot Control Block) method of booting. It seems that as per the errta, it is bugged for large SD cards (2GB+). To enable booting via normal partitions on the SD card the board has to be booted into recovery mode and opened on the desktop through the bitburner/OTP burner program. Then burn the OTP bits to enable MBR based booting, if you don't burn them then the MCU will always look for a BCB instead of using the MBR.

### Resources:
- [Koliqi](https://github.com/koliqi/imx23-olinuxino): amazing resource for start to finish for the mx233
- [Jancc](http://www.jann.cc/2013/02/07/u_boot_for_the_imx233_olinuxino.html): somewhat outdated guide on the MX233 but still workable
- [Karri](http://www.karrikivela.fi/?p=71): New guide on using the mx233, meh quality

### Resources blob from OneTab
- [imx233 bootlets and no battery board | Freescale Community](https://community.freescale.com/thread/303722)
- [First Linux board With kicad | LibreCalc](http://www.librecalc.com/en/blog/premier-circuit-linux/)
- [i.MX233: information about SD/MMC boot from BCB | Freescale Community](https://community.freescale.com/thread/311484)
- [iMX233-OLinuXino - Linux on ARM - eewiki](https://www.eewiki.net/display/linuxonarm/iMX233-OLinuXino)
- [IMX233 - Olimex](https://www.olimex.com/wiki/IMX233)
- [All Boards LTIB Config Ubuntu | Freescale Community](https://community.freescale.com/docs/DOC-1442)
- [U-Boot for the iMX233-OLinuXino — Christian's Blog](http://www.jann.cc/2013/02/07/u_boot_for_the_imx233_olinuxino.html)
- [A new SD card image for the iMX233-OLinuXino — Christian's Blog](http://www.jann.cc/2013/02/04/a_new_image_for_the_imx233_olinuxino.html)
- [Index of /pub/archlinuxarm/os/](http://mirror.lug.udel.edu/pub/archlinuxarm/os/)
- [FTDI PID Unbrick](http://www.minipwner.com/index.php/unbrickftdi000)
- [embedded - Why would copying a micro SD card using dd fail to produce a bootable card? - Reverse Engineering Stack Exchange](https://reverseengineering.stackexchange.com/questions/6666/why-would-copying-a-micro-sd-card-using-dd-fail-to-produce-a-bootable-card)
- [SD-card with ArchLinux will not boot on Olimex iMX233-OLinuXino-MAXI](https://www.olimex.com/forum/index.php?topic=606.0)
- [g-lab – u-boot bootloader for imx23-olinuxino board](http://g-lab.ca/u-boot-bootloader-for-imx23-olinuxino-board/)
- [Newbie question: can iMx233 Olinuxino-Micro boot from USB?](https://www.olimex.com/forum/index.php?topic=3590.5;wap2)
- [dcfldd](http://dcfldd.sourceforge.net/)
- [sasamy.narod.ru/IMX23_ROM_Error_Codes.pdf](http://sasamy.narod.ru/IMX23_ROM_Error_Codes.pdf)
- [i.MX233 board USB not detected on win 7 | Freescale Community](https://community.freescale.com/thread/303440)
- [Booting custom I.MX233 board via BCB | Freescale Community](https://community.freescale.com/thread/321792)
- [iMX233-OLINUXINO SOFTWARE DEVELOPMENT PROGRESS | olimex](http://olimex.wordpress.com/2012/04/20/imx233-olinuxino-software-development/)
- [Re: Re: Re: Re: i.MX233 Hand-Held Multimedia Board - Google Groups](https://groups.google.com/forum/#!topic/rockboxplayer/kRdNDXUpfzw)
- [mx233 HTLLC - Google Search](https://www.google.com/search?q=x80502004&rlz=1C1CHFX_enUS593US593&oq=x80502004&aqs=chrome..69i57.1279j0j1&sourceid=chrome&es_sm=122&ie=UTF-8#newwindow=1&q=mx233+HTLLC)
- [iMX233-OLinuXino - Linux on ARM - eewiki](https://ww.eewiki.net/pages/viewpage.action?pageId=20349076)
- [mx233 bcb signature - Google Search](https://www.google.com/search?q=mx233+bcb+signature&rlz=1C1CHFX_enUS593US593&oq=mx233+bcb+signature&aqs=chrome..69i57.7118j0j9&sourceid=chrome&es_sm=122&ie=UTF-8)
- [sasamy.narod.ru/IMX23_ROM_Error_Codes.pdf](http://sasamy.narod.ru/IMX23_ROM_Error_Codes.pdf)