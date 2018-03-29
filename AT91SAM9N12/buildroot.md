# Buildroot

## The heck is Buildroot?

The [Old School](OldSchool/readme.md) guide shows how to set the kernel and root file system up by hand which while a great learning experience is extremely tedeious and error prone. A few years ago among a mass of shell and python scripts in an attempt to automate this process, the community decided to make [BuildRoot](https://buildroot.org/). This automates all of the following for you;

- Downloading and cross compiling a toolchain
- Downloading and cross compiling the kernel
- Downloading and cross compiling busybox
- Downloading and cross compiling tons of packages (htop, screen, python, ruby, etc)
- Dependancy management for packages
- Wrappers for menuconfig of busybox, linux, and more
- Optionally can handle AT91 Bootstrap and U-Boot
- Creates a root file system (and even compresses it)
- Wrapped up in makefiles which support ```nconfig```

In short, Busybox is an amazing tool that takes all the pain out of setting up a Linux based system. What about [Yocto](https://www.yoctoproject.org/)? I didn't get a chance to actually try it out yet, so Buildroot it is!

Going back to our original goal, we want a minimal system that can fit in under 4 Megabytes. This means no xorg (no graphical interface), no package manager, no Python or Ruby, only the basic necessities. Conceptually we need three diffirent items, the Linux Kernel (the kernel), the Root File System (ROOTFS, contains busybox and our applications), and Device Tree.
