# Embedded Linux System

### Repository contents.
The repository is divided into two SOC's, one being Atmel's AT91SAM9N12 which is what the currently working board uses, and the other being Freescale's I.MX223. Each SOC subdir contains schematics, board files, the required code modifications in the form of git patches to the secondary bootloaders, U-Boot, etc, and various scripts. The current folder structure doesn't represent the folder structure which the scripts are run in, since this is meant solely for myself for now the most I can say is to look at the paths present in the scripts to see what script goes where.

### Getting started
Right now, you have to manually find and download all the needed dependancies. A script will hopefully be written someday to automate downloading and patching all the files.

[Pictures](https://plus.google.com/photos/110672839466942103532/albums/6084477100140148161?authkey=CI7x0czR_vKqowE)

### Thanks Henrik!
For those who don't know, Henrik made [a board](http://hforsten.com/making-embedded-linux-computer.html) based on Atmel's SAM9N12 SoC roughly a year ago. This is what showed me as well as likely hundreds of others that such a thing is possible to do at home without thousands of dollars in equipment. His fantastic walkthrough is what inspired for me and guided me through nights of confusion and bewilderment, and if it weren't for him and his walkthrough this would have not been possible. So, Henrik, thank you!
