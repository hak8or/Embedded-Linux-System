echo "Clear the SD card partition first"
dd if=/dev/zero of=/dev/sdb1

echo "And now we write it to the SD card."
dd if=uboot.sb of=/dev/sdb1 bs=512

echo "Sync things up to make sure we are right"
sync

echo "Dumping the image to check if things went back"
mkdir verification_dumps
cd verification_dumps
rm part1_dump
dd if=/dev/sdb1 of=part1_dump
sync


echo "Done, take out the card"
