cp ${1}/boot/updater_prebuilt.db ${TOP}
cd ${TOP}
sed -i "s,[^ *]zImage.*;,\tzImage=\"${1}/boot/zImage\";," updater_prebuilt.db
sed -i "s,[^ *]sdram_prep.*;,\tsdram_prep=\"${1}/boot/boot_prep\";," updater_prebuilt.db
sed -i "s,[^ *]linux_prep.*;,\tlinux_prep=\"${1}/boot/linux_prep\";," updater_prebuilt.db
sed -i "s,[^ *]power_prep.*;,\tpower_prep=\"${1}/boot/power_prep\";," updater_prebuilt.db

elftosb2 -d -z -c updater_prebuilt.db -o updater.sb

rm -f updater_prebuilt.db

