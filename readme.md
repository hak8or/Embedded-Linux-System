# Embedded Linux System

### Repository contents.
The repository is divided into two SOC's, one being Atmel's AT91SAM9N12 which is what the currently working board uses, and the other being Freescale's I.MX223. Each SOC subdir contains schematics, board files, the required code modifications in the form of git patches to the secondary bootloaders, U-Boot, etc, and various scripts. The current folder structure doesn't represent the folder structure which the scripts are run in, since this is meant solely for myself for now the most I can say is to look at the paths present in the scripts to see what script goes where.

### Getting started
Right now, you have to manually find and download all the needed dependancies. A script will hopefully be written someday to automate downloading and patching all the files.

[Pictures](https://goo.gl/photos/XjbDx4G7ZKULxgLcA)

### Thanks Henrik!
For those who don't know, Henrik made [a board](http://hforsten.com/making-embedded-linux-computer.html) based on Atmel's SAM9N12 SoC roughly a year ago. This is what showed me as well as likely hundreds of others that such a thing is possible to do at home without thousands of dollars in equipment. His fantastic walkthrough is what inspired for me and guided me through nights of confusion and bewilderment, and if it weren't for him and his walkthrough this would have not been possible. So, Henrik, thank you!

### Propogation online
- [HackaDay](http://hackaday.com/2015/04/10/building-super-small-linux-computers-from-scratch/)
- [Elektroda.pl](http://www.elektroda.pl/rtvforum/topic3019687.html)
- [Dangerous Prototypes](http://dangerousprototypes.com/2015/04/07/embedded-linux-system/)
- [ARM](http://community.arm.com/groups/embedded/blog/2015/04/16/maker-builds-a-diy-embedded-linux-computer)
- [Atmel](http://blog.atmel.com/2015/04/10/building-a-diy-embedded-linux-processor/)
