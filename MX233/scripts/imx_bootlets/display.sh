echo "Wiping possible old dumps ... \c"
rm sdb_8
rm sdb1_8
rm sdb2_8
rm sdb2_end
rm sdb_end
echo "OK"

echo "Dumping various points on the card ... "
dd if=/dev/sdb of=sdb_8 bs=512 count=8
sync

dd if=/dev/sdb1 of=sdb1_8 bs=512 count=8
sync

dd if=/dev/sdb2 of=sdb2_8 bs=512 count=8
sync

dd if=/dev/sdb2 of=sdb2_end bs=512 skip=31289340
sync

dd if=/dev/sdb of=sdb_end bs=512 skip=31324159
sync
echo "OK"

echo "\n========== SDB first 8 sectors =========="
echo "If card uses an MBR, contains a magic num of 0x55AA here somewhere!"
hd sdb_8

echo "\n========== SDB1 first 8 sectors =========="
hd sdb1_8

echo "\n========== SDB2 first 8 sectors =========="
hd sdb2_8

echo "\n========== SDB2 last few sectors =========="
hd sdb2_end

echo "\n========== SDB last few sectors =========="
echo "If card uses an BCB, contains a magic num of 0x33221100 here somewhere!"
hd sdb_end