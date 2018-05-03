# Networking

Now that we have the USB issue solved, we have to ensure that the driver for our dongle is being included as shown earlier. This can be verified by ```make linux-nconfig``` and under ```Device Drivers->Network Device Support->Wireless Lan->Atheros/Qualcom devices``` being enabled, and support for ```Atheros HTC based wireless cards``` also being checked. The firmware itself for our dongle must also be enabled in buildroot via ```Target Packages->Hardware Handling->Firmware->Linux-firmware->Wifi firmware->Atheros 9271```. The process is the same for other WiFi dongles. When you plug the dongle in, you should be seeing the following in dmesg or the terminal:

```none
usb 1-1: new full-speed USB device number 3 using at91_ohci
usb 1-1: New USB device found, idVendor=0cf3, idProduct=9271
usb 1-1: New USB device strings: Mfr=16, Product=32, SerialNumber=48
usb 1-1: Product: USB2.0 WLAN
usb 1-1: Manufacturer: ATHEROS
usb 1-1: SerialNumber: 12345
....
------------[ cut here ]------------
WARNING: CPU: 0 PID: 3 at drivers/usb/core/urb.c:471 usb_submit_urb+0x24c/0x488
usb 1-1: BOGUS urb xfer, pipe 1 != type 3
Modules linked in:
CPU: 0 PID: 3 Comm: kworker/0:0 Tainted: G        W        4.15.18 #4
Hardware name: Atmel AT91SAM9
Workqueue: events request_firmware_work_func
[<c010734c>] (unwind_backtrace) from [<c0105344>] (show_stack+0x10/0x14)
[<c0105344>] (show_stack) from [<c010e364>] (__warn+0xd4/0xec)
[<c010e364>] (__warn) from [<c010e3b0>] (warn_slowpath_fmt+0x34/0x44)
[<c010e3b0>] (warn_slowpath_fmt) from [<c02e8874>] (usb_submit_urb+0x24c/0x488)
[<c02e8874>] (usb_submit_urb) from [<c02d7e44>] (hif_usb_send+0x268/0x2b8)
[<c02d7e44>] (hif_usb_send) from [<c02d854c>] (ath9k_wmi_cmd+0x124/0x178)
[<c02d854c>] (ath9k_wmi_cmd) from [<c02dd364>] (ath9k_regwrite+0xd8/0xdc)
[<c02dd364>] (ath9k_regwrite) from [<c02b7994>] (ath9k_hw_init_pll+0x2b8/0x56c)
[<c02b7994>] (ath9k_hw_init_pll) from [<c02b9398>] (ath9k_hw_disable+0x40/0x48)
[<c02b9398>] (ath9k_hw_disable) from [<c02ddce4>] (ath9k_htc_probe_device+0x6fc/0x870)
[<c02ddce4>] (ath9k_htc_probe_device) from [<c02d6738>] (ath9k_htc_hw_init+0x10/0x30)
[<c02d6738>] (ath9k_htc_hw_init) from [<c02d78d4>] (ath9k_hif_usb_firmware_cb+0x54c/0x5f4)
[<c02d78d4>] (ath9k_hif_usb_firmware_cb) from [<c028d004>] (request_firmware_work_func+0x38/0x60)
[<c028d004>] (request_firmware_work_func) from [<c011f6a4>] (process_one_work+0x1b8/0x2fc)
[<c011f6a4>] (process_one_work) from [<c0120218>] (worker_thread+0x2b0/0x428)
[<c0120218>] (worker_thread) from [<c0123f14>] (kthread+0xfc/0x114)
[<c0123f14>] (kthread) from [<c01024e0>] (ret_from_fork+0x14/0x34)
---[ end trace 58ebef53bfa50e07 ]---
....
```

## Ugh, more issues?

What the heck is this ```usb 1-1: BOGUS urb xfer, pipe 1 != type 3``` doing spamming our console? Looking around, [there](https://github.com/torvalds/linux/commit/2b721118b7821107757eb1d37af4b60e877b27e7) has been some work on this, and someone [else](https://www.spinics.net/lists/linux-wireless/msg165591.html) getting this issue. Sadly, there is no trivial proper fix for this.

This requires a little setup first though! When writing this guide, I had only two dongles on hand, an OurLink AC600 that is based on an ```8812au``` which only has an OOT (Out Of Tree or not mainlined into Linux) [driver](https://github.com/mk-fg/rtl8812au). There are [no plans](https://github.com/mk-fg/rtl8812au#upstreaming-status) to upstream the 8812au relevant code because the driver quality is apparently very poor and there isn't enough interest to clean it up, especially considering it's 5 years old at this point. Instead, I am using the [RNX-N150HG](https://wikidevi.com/wiki/Rosewill_RNX-N150HG) which is based off the Atheros 9271. Unfortunately, the driver [doesn't currently support](https://github.com/qca/open-ath9k-htc-firmware/wiki/usb-related-issues#bogus-urb-xfer-pipe-1--type-3) USB Full Speed, which is all the SAM9N12 can muster. You say it's USB 2.0 though, it should therefore do Full Speed! Well, that's marketing for ya, calling something USB 2.0 which should therefore support USB High-Speed (480 Mbps) when it actually can only handle USB Full-Speed (12 Mbps).

Well, the driver says it's not supported to run at Full-Speed, not that it doesn't work. In my experience it seems to work 9/10th of the time when booting, so good enough for me. Instead, let's work on getting rid of ```usb 1-1: BOGUS urb xfer, pipe 1 != type 3``` spam we get in the dongle. We can just disable all logging via ```dmesg -n 1``` but then we loose other potentially relevant information. Instead, we can change ```dev_WARN(..)``` to ```dev_warn_once(...)``` in ```drivers/usb/core/urb.c``` where this issue happens, which will make the warning show up only once. We could have used ```dev_warn_ratelimited(...)``` instead, to rate limit the warning so it only shows up at most 10 times every 5 seconds, but I found this to still spam the logs too much.

```git
[hak8or@hak8or linux_commit]$ cat 0001-USB-Bogus-Pipe-warning-rate-limited.patch
From 41595efeebbae49555ac1917d0adaee98d1fa4ee Mon Sep 17 00:00:00 2001
From: Marcin Ziemianowicz <marcin@ziemianowicz.com>
Date: Tue, 1 May 2018 22:54:52 -0400
Subject: [PATCH] USB: Bogus Pipe warning rate limited

Fix for just my board to prevent errors from overflow our logs. This
error is not critical but happens extremely often due to a driver issue
which I am fine with. This will never be mainlined since it's a hack.
---
 drivers/usb/core/urb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/core/urb.c b/drivers/usb/core/urb.c
index f51750bc..17ef20fc 100644
--- a/drivers/usb/core/urb.c
+++ b/drivers/usb/core/urb.c
@@ -475,7 +475,7 @@ int usb_submit_urb(struct urb *urb, gfp_t mem_flags)
 
        /* Check that the pipe's type matches the endpoint's type */
        if (usb_urb_ep_type_check(urb))
-               dev_WARN(&dev->dev, "BOGUS urb xfer, pipe %x != type %x\n",
+               dev_warn_once(&dev->dev, "BOGUS urb xfer, pipe %x != type %x\n",
                        usb_pipetype(urb->pipe), pipetypes[xfertype]);
 
        /* Check against a simple/standard policy */
-- 
2.17.0
```

Now our boot log looks much cleaner, though we did loose out on the stack trace, but we know where this is coming from anyways so oh well.

```none
usb 1-1: new full-speed USB device number 2 using at91_ohci
usb 1-1: New USB device found, idVendor=0cf3, idProduct=9271
usb 1-1: New USB device strings: Mfr=16, Product=32, SerialNumber=48
usb 1-1: Product: USB2.0 WLAN
usb 1-1: Manufacturer: ATHEROS
usb 1-1: SerialNumber: 12345
usb 1-1: ath9k_htc: Firmware ath9k_htc/htc_9271-1.4.0.fw requested
usb 1-1: ath9k_htc: Transferred FW: ath9k_htc/htc_9271-1.4.0.fw, size: 51008
usb 1-1: BOGUS urb xfer, pipe 1 != type 3
ath9k_htc 1-1:1.0: ath9k_htc: HTC initialized with 33 credits
ath9k_htc 1-1:1.0: ath9k_htc: FW Version: 1.4
ath9k_htc 1-1:1.0: FW RMW support: On
ieee80211 phy0: Atheros AR9271 Rev:1
```

## WPA Supplicant

Next comes being able to connect to a secure network (WPA2 in my case). For that you need a [Supplicant](https://www.wikiwand.com/en/Supplicant_(computer)) which can handle WPA, in our case being [WPA Supplicant](https://wiki.archlinux.org/index.php/WPA_supplicant). Sadly it is huge at a **whopping** 408 kB, and after fiddling with it's ```defconfig``` I wasn't able to find any way to greatly and easily reduce it's size. It also doesn't support kconfig and therefore menuconfig, so the attempts were mostly trial and error due to the lack of dependancy information. Enable it in buildroot via a ```make nconfig```, and configuring it can be done as per a few great guides, like [this](http://www.linuxfromscratch.org/blfs/view/svn/basicnet/wpa_supplicant.html) from LFS, [this](https://wiki.gentoo.org/wiki/Wpa_supplicant) from gentoo, or [this](https://wiki.archlinux.org/index.php/WPA_supplicant) from, of course, Arch. Lastly, we need ```iw``` (only ```52 kB```) because it is extremely helpful for interfacing with wireless networks, and dhcpd (only ```92 kB```) to get an IPv4 address.

```bash
[hak8or@CT108 buildroot-2018.02.1]$ ls -la --block-size=k output/images/
total 3305K
drwxr-xr-x 2 hak8or hak8or    1K May  2 05:21 .
drwxr-xr-x 6 hak8or hak8or    1K May  2 03:25 ..
-rw-r--r-- 1 hak8or hak8or   18K May  2 05:21 at91sam9n12ek_custom.dtb
-rw-r--r-- 1 hak8or hak8or 1476K May  2 05:35 rootfs.squashfs
-rw-r--r-- 1 hak8or hak8or 1748K May  2 05:21 zImage
```

To connect to a WiFi network we need to create the WiFi login key and then tell wpa_supplicant to actually connect.

```bash
# Create a file containing the login credentials.
wpa_passphrase OpenWrt ssidpassword > /tmp/w.conf

# Connect to the network using the login credentials.
wpa_supplicant -B -i wlan0 -c /tmp/w.conf

# Get a IPv4 address using dhcpd if it didn't fetch one automatically.
dhcpd
```

And now we have a connection!

```none
# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: sit0@NONE: <NOARP> mtu 1480 qdisc noop qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq qlen 1000
    link/ether 68:1c:a2:01:17:0b brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.227/24 brd 192.168.1.255 scope global wlan0
       valid_lft forever preferred_lft forever
# ping hak8or.com
PING hak8or.com (107.191.39.171): 56 data bytes
64 bytes from 107.191.39.171: seq=0 ttl=50 time=21.703 ms
64 bytes from 107.191.39.171: seq=1 ttl=49 time=24.823 ms
64 bytes from 107.191.39.171: seq=2 ttl=49 time=19.870 ms
64 bytes from 107.191.39.171: seq=3 ttl=50 time=24.777 ms
^C
--- hak8or.com ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 19.870/22.793/24.823 ms
```

## CRDA

What about the mention of ```cfg80211: failed to load regulatory.db```? Well, after a [decent](https://www.linuxquestions.org/questions/showthread.php?p=5814902#post5814902) bit of googling, turns out this is related to regulatory issues of what areas are allowed to use what channels for Wifi. A recent update to the Linux kernel resulted in needing to use ```crda``` (which is a monsterous 320 kB) just to communicate with the kernel this regulatory information.

```none
# Boot log ...
sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
NET: Registered protocol family 17
Loading compiled-in X.509 certificates
cfg80211: Loading compiled-in X.509 certificates for regulatory database
cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
cfg80211: failed to load regulatory.db

# iw reg get
global
country 00: DFS-UNSET
        (2402 - 2472 @ 40), (6, 20), (N/A)
        (2457 - 2482 @ 20), (6, 20), (N/A), AUTO-BW, PASSIVE-SCAN
        (2474 - 2494 @ 20), (6, 20), (N/A), NO-OFDM, PASSIVE-SCAN
        (5170 - 5250 @ 80), (6, 20), (N/A), AUTO-BW, PASSIVE-SCAN
        (5250 - 5330 @ 80), (6, 20), (0 ms), DFS, AUTO-BW, PASSIVE-SCAN
        (5490 - 5730 @ 160), (6, 20), (0 ms), DFS, PASSIVE-SCAN
        (5735 - 5835 @ 80), (6, 20), (N/A), PASSIVE-SCAN
        (57240 - 63720 @ 2160), (N/A, 0), (N/A)
```

By default we can seem to access all channels, and the device does currently work, so good enough for me. Therefore, we won't go over installing CRDA and getting it to work, partly because I also wasn't able to get it to work.

[Next](Packages.md) up we will install some packages and play around a bit.
