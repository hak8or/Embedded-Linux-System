git clone git://git.denx.de/u-boot.git u-boot.git
cd u-boot.git/
git checkout v2013.07 -b tmp
wget -c https://raw.github.com/eewiki/u-boot-patches/master/v2013.07/0001-mx23_olinuxino-uEnv.txt-bootz-n-fixes.patch
patch -p1 < 0001-mx23_olinuxino-uEnv.txt-bootz-n-fixes.patch
wget -c https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/alarm/uboot-olinuxino/alarm.patch
patch -p1 < alarm.patch

# For debugging with SJtag
wget -c http://www.jann.cc/_downloads/serial_jtag_activation_for_u-boot.patch
patch -p1 < serial_jtag_activation_for_u-boot.patch

# Get out of the git repo.
cd ..

# Download the Arm bare metal cross-compiler from launchpad
wget https://launchpad.net/gcc-arm-embedded/4.7/4.7-2013-q1-update/+download/gcc-arm-none-eabi-4_7-2013q1-20130313-linux.tar.bz2
tar -xjf gcc-arm-none-eabi-4_7-2013q1-20130313-linux.tar.bz2

# Add the new toolchain to path
# echo "export PATH=\$PATH:`pwd`/gcc-arm-none-eabi-4_7-2013q1/bin" >> ~/.bashrc
echo "export PATH=\$PATH:`pwd`/gcc-arm-none-eabi-4_7-2013q1/bin" >> ~/.zshrc
# source ~/.bashrc
source ~/.zshrc

# And  check that change.
echo "================================================="
which arm-none-eabi-gcc
echo "================================================="

# Get the elftosb file to do that crazy encryption nonsense.
wget http://repository.timesys.com/buildsources/e/elftosb/elftosb-10.12.01/elftosb-10.12.01.tar.gz
tar -xzf elftosb-10.12.01.tar.gz
cd elftosb-10.12.01/

# Some more patches.
wget wget http://repository.timesys.com/buildsources/e/elftosb/elftosb-10.12.01/elftosb-10.12.01-libm.patch
patch -p1 < elftosb-10.12.01-libm.patch
wget http://repository.timesys.com/buildsources/e/elftosb/elftosb-10.12.01/elftosb-10.12.01-fix-header-path.patch
patch -p1 < elftosb-10.12.01-fix-header-path.patch

# Make elftosb
make

# Do some funky symlinking.
cp bld/linux/elftosb /usr/local/bin
ln -s /usr/local/bin/elftosb /usr/local/bin/elftosb2

# Go back into the git repo
cd ../u-boot.git/

# And compile uboot.
make ARCH=arm CROSS_COMPILE=arm-none-eabi- distclean
make ARCH=arm CROSS_COMPILE=arm-none-eabi- mx23_olinuxino_config
make ARCH=arm CROSS_COMPILE=arm-none-eabi- u-boot.sb
# The u-boot.sb step should call elftosb!!!

# Copy the sb file out of the uboot dir for easier access.
cp u-boot.sb ../uboot.sb