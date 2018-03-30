# Device Tree

## Before Device Tree

Years ago when ARM for embedded linux was still in its infancy, all the vendors were putting their diffirent peripherals (HDMI driver, SPI driver, where DRAM gets mapped to, clock configuration, etc) in diffirent areas in the address space. The quickiest and dirtiest solution to this was simply hardcoding these changes in the kernel and in tree drivers for each SOC and design, which resulted in kernels images that were not portable across designs. Other information would also be passed to the kernel via registers during boot. This is why often times there would be a diffirent image to flash to an SD card for each board, and using the wrong image resulted in a barely, if at all, functional system.

Why does this seem not to be an issue for x86? Years ago when IBM was still making desktops, IBM wrote *the* BIOS (Basic Input Output System) which attempted to abstract away the underlying hardware and provide some [functions](https://wiki.osdev.org/BIOS) for the OS, like setting the cursor position and [writing text](https://protas.pypt.lt/informatika/assembler/writing_to_the_screen) to the screen. Going further, IBM also made a [standard](http://www.tuner.tw/OMEGA%20CD/zsection/MEM__MAP.PDF) (like what gets mapped to where in the address space) which resulted in the whole "IBM Compatible" PC world. It would initialize all the hardware and do crazy things like attempt to upload a program from the keyboard port into RAM. Most importantly though, the BIOS also reported to the OS what hardware was present on the system. Years later we got [ACPI](https://wiki.osdev.org/ACPI) which did a better job of reporting and interacting with underlying hardware, and now we have the next incarnation of the BIOS called [UEFI](https://wiki.osdev.org/UEFI).

Going back to ARM and today, the lack of such hardware probing and reporting was a huge problem and kept getting worse as time went on because maintaining these seperate kernels was extremely time consuming. Vendors tended to release a modified kernel for the design and that's it, no updating to a newer kernel unless you had a huge amount of time on your hands to do it yourself. Not to mention, hardware vendors generally seem to tend to just throw hardware out in the wind with a "hard work is done, now you software people do everything" attitude, so this isn't too suprising. Needless to say, this was a total nightmare on ARM.

As the Linux Kernel maintainers saw this horror show unfurl itself in front of them gradually but steadly with no signs of ARM or vendors stepping up to fix this problem, Linus [complained](http://thread.gmane.org/gmane.linux.ports.arm.kernel/113895).

> On Mon, Apr 18, 2011 at 8:17 AM, Alexey Zaytsev
>  wrote:
> >
> > Could you please just apologize for the pointless diffstat complain,
> > so we could go on?
> 
> Ehh. They aren't pointless, and I'm _this_ close to just stopping
> pulling from some people unless things improve.
> 
> > Dear Russel.
> >
> > Please don't take the offense. Linus might be a dickhead at times, and
> > sometimes he's wrong, but I'm sure he did not mean to hurt you.
> 
> Umm. The "some people" who need to get their shit together was never
> Russell (and we've been emailing in private about it). We may not
> agree about every detail, but on the whole we're not at all butting
> heads.
> 
> Why do you think he posted that email with those arm statistics?
> 
> It's the _machine/platform_ guys who are trouble.
> 
> Hint for anybody on the arm list: look at the dirstat that rmk posted,
> and if your "arch/arm/{mach,plat}-xyzzy" shows up a lot, it's quite
> possible that I won't be pulling your tree unless the reason it shows
> up a lot is because it has a lot of code removed.
> 
> People need to realize that the endless amounts of new pointless
> platform code is a problem, and since my only recourse is to say "if
> you don't seem to try to make an effort to fix it, I won't pull from
> you", that is what I'll eventually be doing.
> 
> Exactly when I reach that point, I don't know.
> 
> Linus

## Post Device Tree

With Linus finally (and rightfully so) putting a halt on such nonsense from the vendors, the community got to work. Inspired by how Sun used [Open Firmware](https://lwn.net/Articles/209301/) on SPARC (before they got bought by Oracle) handled giving information to the kernel about what hardware is present on the system, Device Tree was born. Check out Open Firmware by the way, it's amazing, it even has a FORTH interpreter that can do TCP/IP and more in under 350 KB!

Device tree relies on you supplying a tree of nodes with each node specfying parameters that the associated driver for the node may for configuration. The vendor gives a ```.dtsi``` file which describes all the peripherals the SOC has such as where the SPI register interface is located in the address space and what type of driver to use for the SPI peripheral. For mainline linux, this file is provided in the ```arch/arm/boot/dts/``` folder, in our case being [at91sam9n12.dtsi](https://github.com/torvalds/linux/blob/master/arch/arm/boot/dts/at91sam9n12.dtsi). As an example, here is what the SPI node looks like. Notice it includes the address of the register block associated with the SPI register, what it's compatible with (which driver to use), the clock source, and most importantly setting it's status to disabled.

```none
spi0: spi@f0000000 {
    #address-cells = <1>;
    #size-cells = <0>;
    compatible = "atmel,at91rm9200-spi";
    reg = <0xf0000000 0x100>;
    interrupts = <13 IRQ_TYPE_LEVEL_HIGH 3>;
    dmas = <&dma 1 AT91_DMA_CFG_PER_ID(1)>,
            <&dma 1 AT91_DMA_CFG_PER_ID(2)>;
    dma-names = "tx", "rx";
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_spi0>;
    clocks = <&spi0_clk>;
    clock-names = "spi_clk";
    status = "disabled";
};
```

When the kernel boots and parses the Device Tree, it finds the "compatible" field for each node and searches for drivers which have been both compiled into the kernel and advertise themselves as matching with the "compatible" node field. In this case, the kernel will look for a driver that has been compiled in which can work with a "at91rm9200-spi" driver for the "Atmel" SOC. But, since the status is disabled, the driver won't actually load.

This is where a ```.dts``` file comes in. Our board is based on the SAM9N12EK from Atmel, so we should be able to base our ```.dts``` file on the already provided [at91sam9n12ek.dts](https://github.com/torvalds/linux/blob/master/arch/arm/boot/dts/at91sam9n12ek.dts). Looking at the SPI node here, we get this;

```none
spi0: spi@f0000000 {
    status = "okay";
    cs-gpios = <&pioA 14 0>, <0>, <0>, <0>;
    m25p80@0 {
        compatible = "atmel,at25df321a";
        spi-max-frequency = <50000000>;
        reg = <0>;
    };
};
```

A ```.dts``` file is meant to say what peripherals are present and used in on a board. Notice at the top of the file it says ```#include "at91sam9n12.dtsi"```, which pulls in all the nodes, including the ```status = "disabled";``` mentions. Conflicting defenitions (```status = "disabled/Okay";``` for example) will be overwritten with the most recent mention (the ```.dts``` file). In effect, the "top" file will overlay itself over older files and overwrite conflicting node parameters. Therefore, when in the ```.dts``` file a peripheral is marked with ```status = "okay";``` this will take priority over any older mentions, in effect telling the kernel to enable the driver for the peripheral. The driver then comes in and using the other information in the node will configure the peripheral, in this case being the [Atmel SPI driver](https://github.com/torvalds/linux/blob/master/drivers/spi/spi-atmel.c).

The driver advertises itself as compatible [here](https://github.com/torvalds/linux/blob/0b412605ef5f5c64b31f19e2910b1d5eba9929c3/drivers/spi/spi-atmel.c#L1820) and pulls in which pins to use as chip select from the Device Tree [here](https://github.com/torvalds/linux/blob/0b412605ef5f5c64b31f19e2910b1d5eba9929c3/drivers/spi/spi-atmel.c#L1492).

Lastly, the device tree is not stored as just a big text file on the device. It's compiled using ```dtc``` into a single ```.dtb``` (device tree binary) file. When the kernel is booting, the address of this file is provided in one of the CPU registers. As time went on, the community has done an amazing job porting much of the old code into a device tree complaint format, as shown [here](https://lwn.net/Articles/572692/) in another probably better writeup. The key take away from this is that a device tree is just a way of describing to the kernel what hardware is present, where in the address map it is, what driver to use for interacting with it, and various optional parameters.

## Custom Device Tree

Time to make our own device tree. We know we want the following;

- Serial port for Dataflash (root file system is not copied to RAM)
- Dataflash IC itself on SPI0 peripheral
- Partition the Dataflash for all our data
- USB Host (it's only 4 lines, will use this for a Wifi dongle)

At the top level we have a memory node to tell the kernel where memory is and how much of it the Kerenl is allowed to use, what clock sources there are, and then peripherals mapped onto various busses. In ARM there are a few busses as per spec, in our case the USB peripheral is directly on the AHB bus. From the AHB bus branches off a slower APB bus to which the SPI peripheral is attached to. The SPI bus has only one device, an ```AT45``` based Dataflash IC, in which flash memory is mapped using [MTD](http://www.linux-mtd.infradead.org/doc/general.html) across 5 partitions. Each partition node has a "reg" field which has two arguments, the offset and how large this partition is.

```none
/*
 * at91sam9n12ek.dts - Device Tree file for AT91SAM9N12-EK board
 *
 *  Copyright (C) 2012 Atmel,
 *                2012 Hong Xu <hong.xu@atmel.com>
 *
 * Licensed under GPLv2 or later.
 */
/dts-v1/;
#include "at91sam9n12.dtsi"

/ {
    model = "Atmel AT91SAM9N12-EK";
    compatible = "atmel,at91sam9n12ek", "atmel,at91sam9n12", "atmel,at91sam9";

    memory {
        reg = <0x20000000 0x4000000>;
    };

    clocks {
        main_xtal {
            clock-frequency = <16000000>;
        };
    };

    ahb {
        apb {
            dbgu: serial@fffff200 {
                status = "okay";
            };

            spi0: spi@f0000000 {
                status = "okay";
                cs-gpios = <&pioA 14 0>, <0>, <0>, <0>;
                flash@0 {
                    status = "okay";
                    compatible = "atmel,at45";
                    spi-max-frequency = <25000000>;
                    reg = <0>;

                    partitions {
                        compatible = "fixed-partitions";
                        #address-cells = <1>;
                        #size-cells = <1>;

                        partition@0 {
                            label = "AT91Bootstrap";
                            reg = <0x00 0x26D8>;
                            read-only;
                        };

                        partition@2800 {
                            label = "DeviceTree";
                            reg = <0x2800 0x4B00>;
                            read-only;
                        };

                        partition@7300 {
                            label = "zImage";
                            reg = <0x7300 0x1D8D00>;
                            read-only;
                        };

                        partition@1E0000 {
                            label = "RootFS";
                            reg = <0x1E0000 0x237C00>;
                            read-only;
                        };

                        partition@417C00 {
                            label = "NonVolatile";
                            reg = <0x417C00 0x8400>;
                        };
                    };
                };
            };
        };

        usb0: ohci@500000 {
            num-ports = <1>;
            status = "okay";
        };
    };
};
```

## Passing to the Kernel

When the kernel boots, it expects the address of where the device tree begins in one of the CPU registers, and therefore be exposed in the address space. Since the AT91SAM9N12 does not expose/map the contents of Dataflash from the SPI periperhal in the address space (not to mention that the kernel will attempt to configure the SPI peripheral by starting up it's driver), it must be copied to DRAM. The only way to do this is to inform the bootloader (AT91 Bootstrap) that we want to copy a device tree from Dataflash to DRAM. This will be shown next, after we get Linux compiling.
