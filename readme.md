# Embedded Linux System

### Repository contents.
The repository is divided into two SOC's, one being Atmel's AT91SAM9N12 which is what the currently working board uses, and the other being Freescale's I.MX223. Each SOC subdir contains schematics, board files, the required code modifications in the form of git patches to the secondary bootloaders, U-Boot, etc, and various scripts. The current folder structure doesn't represent the folder structure which the scripts are run in, since this is meant solely for myself for now the most I can say is to look at the paths present in the scripts to see what script goes where.

### Getting started
Right now, you have to manually find and download all the needed dependancies. A script will hopefully be written someday to automate downloading and patching all the files.