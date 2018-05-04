# Making things better

The end goal is to have the system be fairly usable, with the list from before being:

- [x] Boot to a shell and be able to communicate with it over serial
- [x] Read only file system with compression (SquashFS)
- [x] Networking support
- [x] Use the RNX-N150HG USB Wifi dongle to talk to the outside world
- [ ] curl
- [ ] htop
- [ ] stress
- [ ] tmux
- [ ] SSH Server
- [ ] Nano

As of now, the system can boot into a shell and recognize USB devices, specifically our Wifi dongle. Future changes to the system involve userspace instead of kernel space, hence the divide. We will call this a minimal configuration for our system, which if you want to replicate just follow the [replicating documentation](replicate.md).

## Musl vs Glibc vs uClibc-ng

There are three main c standard library implementations out there, each with it's own pro's and con's. [Glibc](https://www.gnu.org/software/libc/libc.html) (GNU C Library) is the big most popular and therefore the "standard". uClibc-ng (a fork of [uClibc](https://www.uclibc.org/FAQ.html#doesnt_suck)) a smaller version of GlibC which removes various (very non relevant for Embedded Systems) backwards compatibility in favor of space. [Musl](https://www.musl-libc.org/intro.html) is a new implementation of the C STDLib under a more permissive and open source friendly license, in addition to being an attempt at writing a new implementation with modern practices in mind. There is a [great](http://www.etalabs.net/compare_libcs.html) comparison which goes over specific differences between these three implementations. This can be changed in buildroot in the ```Toolchain``` entry. Since we are targeting a very small system in terms of flash, we have to see which of these is smaller. This is without any packages yet, so it is really just the size of the stdlib itself.

| Type      | zImage Total | RootFS Total | RootFS Delta |
| --------- | ------------ | ------------ | ------------ |
| uClibc-ng |      1658 kB |      964  kB |         0 kB |
| Glibc     |      1657 kB |      1720 kB |      +760 kB |
| Musl      |      1658 kB |      1036 kB |       +76 kB |

If we just worry about size then you would think, hey, lets go with uClibc-ng, right? To that I say, good luck getting locale to work, and therefore tmux. Instead, in our case we will go with Musl. It's very well supported, has tons of functionality similar to Glibc (refer to previously mentioned comparison chart), and is only 76 kB bigger than uClibc-ng. Most importantly, after spending a few hours trying to get locales to run with uClibc-ng to get tmux to work, I gave up and went with Musl. So Musl it is!

## HTTP Webserver

Buildroot supports a few HTTP webservers, such as Nginx, but we need a small one that can fit in our tiny flash space. Here are a few I looked at and their associated size increase of the zImage.

| Package         | Summary                                                                                         | RootFS Delta |
| :-------------  | :---------------------------------------------------------------------------------------------- | :----------: |
| lighthttpd      | Very active even today, lots of features.                                                       |       212 kB |
| Nginx           | Everyone knows nginx, this removed everything except static file hosting.                       |       146 kB |
| uhttpd          | Written by OpenWRT people, handles CGI and IPv6.                                                |        56 kB |
| thttpd          | Last commit was in 2014, simple, and supports CGI + IPv6.                                       |        36 kB |
| Boa             | Discontinued in 2005.                                                                           |        20 kB |
| DarkHttp        | Last commit was in 2016, simple, no CGI, and supports IPv6.                                     |        60 kB |
| tinyhttpd       | Many versions under this name, shouldn't be used for production. Ridiculously simple and tiny.  |         1 kB |

## Packages

Buildroot also does a fantastic job of dependancy management. It can tell what packages need what libraries or other software and adds it for you. To start off, lets add htop, a great alternative to top which adds colors and just makes visually far more usable. In the buildroot directory, just do ```make nconfig``` and go into ```target packages->System tools``` to enable the htop package. You can also just search for symbols when using nconfig with the F8 key. Afterwards just run make and done. Htop adds 156 kB to our compressed root file system.

Repeating this process for the other packages, here is what the size of each package is when added to our root file system.

| Package         | Summary                                                                                                                    | RootFS Delta |
| :-------------  | :------------------------------------------------------------------------------------------------------------------------- | :----------: |
| WPA_Supplicant  | To connect to wireless networks.                                                                                           |       408 kB |
| Tmux            | Great for when we want to need two or more terminals at once.                                                              |       336 kB |
| Htop            | Vastly prefer over top, used to tell what the state of the system is.                                                      |       156 kB |
| LibCurl + Curl  | Interfacing with web API's.                                                                                                |       148 kB |
| Dropbear + Zlib | Allows us to run an SSH server on our board. Requires Zlib (only 32 kB), 76 kB with or without "Client Programs".          |       108 kB |
| Nano            | Helpful little text editor.                                                                                                |        60 kB |
| Dhrystone       | Can be fun to use for very rough benchmarking.                                                                             |         4 kB |
| Stress          | Stress test the system for IO, CPU, Memory, etc. Sadly can't use stress-ng because we aren't using GlibC due to it's size. |         4 kB |

## Tmux

Tmux requires a UTF-8 locale instead of our current ASCII locale. What is a locale you ask? It is a bunch of information in a file which tells the system what region you are in and therefore what symbols to use for your currency, how to display your time, how to display numbers (comma vs dot for digit groupings), and other formatting which differs across countries. This also tends to be accompanied with the characters themselves.

If tmux is ran without the proper locale setup, then you are greeted with this ```tmux: need UTF-8 locale (LC_CTYPE) but have ASCII```.

## Drop Bear

Since we have network connectivity, we might as well include the ability to connect to the device over SSH, and connect to other devices over SSH. SSH'ing into a system requires either key or password based authentication, but that gives us an issue. Our root file system is read only, and we do not have a overlay to allow writing to it. Therefore, we cannot just create a new user in the running file system or add a password, because both require writing to the file system. Instead, we can have buildroot add a password to the root user under ```System configuration->Root password```. Right now it's set to "pass".
