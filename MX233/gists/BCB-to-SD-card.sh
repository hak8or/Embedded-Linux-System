echo "Remove old files"
rm bcb
rm bcb_512.cfg
rm bcb_sdcard_part.old
rm bcb_sdcard_part.readback

echo "Compiling bcb tool"
gcc bcb.c -o bcb

echo "Running bcb tool"
./bcb

echo "Saving old partition contents to bcb_sdcard_part.old"
dd if=/dev/sdb3 of=bcb_sdcard_part.old

echo "============= Contents of ->OLD<- BCD ============="
hd bcb_sdcard_part.old

echo "Clear the SD card boot block partition first"
dd if=/dev/zero of=/dev/sdb3
sync

echo "Write the BCD to the sd card BCD parition"
dd if=bcb_512.cfg of=/dev/sdb3
sync

echo "Reading back BCD partition for verification"
dd if=/dev/sdb3 of=bcb_sdcard_part.readback

echo "============= Contents of ->NEW<- BCD ============="
hd bcb_sdcard_part.readback

sync
echo "Done, remove card"
