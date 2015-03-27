# Freescale I.MX233 Embedded Linux System

### Status
Currently not working due to issues with DRAM not seeming to be stable. Might have to mess with the timings a good bit more as well as lowering the clock from 133 Mhz to 100 Mhz.

A 22 uF capacitor under the SDHC holder is too tall, causing the SD card to not fully sit in the holder since it can't be closed, so a finger has to be used by pushing the sd card down when in operation.

**NOTE** Don't bother with the BCB (Boot Control Block) method of booting. It seems that as per the errta, it is bugged for large SD cards (2GB+). To enable booting via normal partitions on the SD card the board has to be booted into recovery mode and opened on the desktop through the bitburner/OTP burner program. Then burn the OTP bits to enable MBR based booting, if you don't burn them then the MCU will always look for a BCB instead of using the MBR.

### Resources:
- [Koliqi](https://github.com/koliqi/imx23-olinuxino): amazing resource for start to finish for the mx233
- [Jancc](http://www.jann.cc/2013/02/07/u_boot_for_the_imx233_olinuxino.html): somewhat outdated guide on the MX233 but still workable
- [Karri](http://www.karrikivela.fi/?p=71): New guide on using the mx233, meh quality