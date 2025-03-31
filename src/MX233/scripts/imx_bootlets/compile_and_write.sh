# Original
# make CROSS_COMPILE=arm-linux-gnueabi- BOARD=imx23_olinuxino_dev MEM_TYPE=MEM_DDR1

make clean

make CROSS_COMPILE=arm-none-eabi-

echo "Wiping the SD card"
./wipe.sh

./display.sh

echo "Copying bootlet to SD card"
dd if=sd_mmc_bootstream.raw of=/dev/sdb1
sync

./display.sh