echo "Wiping contents of first partition (U-BOOT)."
dd if=/dev/zero of=/dev/sdb1 bs=512K count=1
sync

# echo "Wiping first 512KB of second partiton (kernel + rootfs)."
# dd if=/dev/zero of=/dev/sdb2 bs=512K count=1
# sync

# echo "Wiping last few sectors of second partiton (ensures BCB is gone)."
# dd if=/dev/zero of=/dev/sdb2 bs=512 seek=31255576
# sync

# echo "Wiping the first 84 MB of second partiton (kernel + rootfs)"
# dd if=/dev/zero of=/dev/sdb2 bs=1M count=84
# sync

# echo "Wiping the MBR, Partition table, etc."
# dd if=/dev/zero of=/dev/sdb bs=512K count=1
# sync
