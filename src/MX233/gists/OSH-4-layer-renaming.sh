proj_name=Lumy

# Do the renames of mid layers
mv $proj_name.G1 $proj_name.G2L
mv $proj_name.G2 $proj_name.G3L

# Rename outline layer
mv $proj_name.GM3 $proj_name.GKO

zip $proj_name.zip $proj_name.*

echo "All gerbers zipped in $proj_name.zip"
echo "Title: Brainy v2"
echo "Description: ARM MPU with DDR2 mem and NAND flash for Linux, V2 with bigger pads"