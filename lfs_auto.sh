cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

source ~/.bash_profile

#compiling a temporary set of tools:
cd $LFS/sources

# Binutils (Pass 1)
tar -xf binutils-2.39.tar.xz
cd binutils-2.39
mkdir -v build
cd build
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror
make
make install
cd ../..
rm -rf binutils-2.39

# GCC (Pass 1)
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
mkdir -v build
cd build
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.36 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-decimal-float   \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
make
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
cd ..
rm -rf gcc-12.2.0

# Part 3: Compilation of the main components of the system

# Function for optimizing compilation
optimize_compilation() {
  local pkg=$1
  shift
  time {
    tar xf $pkg.tar.xz
    cd $pkg
    mkdir build && cd build
    ../configure "$@"
    make -j$(nproc)
    make install
    cd ../..
    rm -rf $pkg
  }
}

# Linux API Headers
optimize_compilation linux-5.19.2 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --with-sysroot=$LFS \
  --with-kernel-headers=/usr/include

# Glibc
optimize_compilation glibc-2.36 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=3.2 \
  --with-headers=/usr/include \
  libc_cv_slibdir=/usr/lib

# Libstdc++ from GCC
tar xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
mkdir -v build
cd build
../libstdc++-v3/configure \
  --host=$LFS_TGT \
  --build=$(../config.guess) \
  --prefix=/usr \
  --disable-multilib \
  --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/12.2.0
make -j$(nproc)
make install
cd ../..
rm -rf gcc-12.2.0

# M4
optimize_compilation m4-1.4.19 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Ncurses
optimize_compilation ncurses-6.3 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./config.guess) \
  --mandir=/usr/share/man \
  --with-manpage-format=normal \
  --with-shared \
  --without-debug \
  --without-ada \
  --without-normal \
  --enable-widec

# Bash
optimize_compilation bash-5.1.16 \
  --prefix=/usr \
  --build=$(support/config.guess) \
  --host=$LFS_TGT \
  --without-bash-malloc

# Coreutils
optimize_compilation coreutils-9.1 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess) \
  --enable-install-program=hostname \
  --enable-no-install-program=kill,uptime

# Diffutils
optimize_compilation diffutils-3.8 \
  --prefix=/usr \
  --host=$LFS_TGT

# File
optimize_compilation file-5.42 \
  --prefix=/usr \
  --host=$LFS_TGT

# Findutils
optimize_compilation findutils-4.9.0 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Gawk
optimize_compilation gawk-5.1.1 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Grep
optimize_compilation grep-3.7 \
  --prefix=/usr \
  --host=$LFS_TGT

# Gzip
optimize_compilation gzip-1.12 \
  --prefix=/usr \
  --host=$LFS_TGT

# Make
optimize_compilation make-4.3 \
  --prefix=/usr \
  --without-guile \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Patch
optimize_compilation patch-2.7.6 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Sed
optimize_compilation sed-4.8 \
  --prefix=/usr \
  --host=$LFS_TGT

# Tar
optimize_compilation tar-1.34 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)

# Xz
optimize_compilation xz-5.2.6 \
  --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess) \
  --disable-static \
  --docdir=/usr/share/doc/xz-5.2.6

# Binutils (Pass 2)
optimize_compilation binutils-2.39 \
  --prefix=/usr \
  --build=$(../config.guess) \
  --host=$LFS_TGT \
  --disable-nls \
  --enable-shared \
  --enable-gprofng=no \
  --disable-werror \
  --enable-64-bit-bfd

# GCC (Pass 2)
tar xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
mkdir -v build
cd build
../configure \
  --build=$(../config.guess) \
  --host=$LFS_TGT \
  --target=$LFS_TGT \
  LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
  --prefix=/usr \
  --with-build-sysroot=$LFS \
  --enable-initfini-array \
  --disable-nls \
  --disable-multilib \
  --disable-decimal-float \
  --disable-libatomic \
  --disable-libgomp \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libvtv \
  --enable-languages=c,c++
make -j$(nproc)
make install
ln -sv gcc /usr/bin/cc
cd ../..
rm -rf gcc-12.2.0

# Part 4: System Setup and Boot Preparation
# Creating important system files and directories
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

cd $LFS/sources
tar xf linux-5.19.2.tar.xz
cd linux-5.19.2
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
cd ..
rm -rf linux-5.19.2

cd $LFS/sources
tar xf glibc-2.36.tar.xz
cd glibc-2.36
patch -Np1 -i ../glibc-2.36-fhs-1.patch
mkdir -v build
cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr \
             --disable-werror \
             --enable-kernel=3.2 \
             --enable-stack-protector=strong \
             --with-headers=/usr/include \
             libc_cv_slibdir=/usr/lib
make -j$(nproc)
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service
cd ../..
rm -rf glibc-2.36

mkdir -pv /etc/ld.so.conf.d
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

include /etc/ld.so.conf.d/*.conf
EOF

cd $LFS/sources
tar xf grub-2.06.tar.xz
cd grub-2.06
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --disable-efiemu \
            --disable-werror
make -j$(nproc)
make install
cd ..
rm -rf grub-2.06

cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,1)

menuentry "LFS 11.2-systemd" {
        linux   /vmlinuz-5.19.2-lfs-11.2-systemd root=/dev/sda3 ro
}
EOF

cd $LFS/sources
tar xf linux-5.19.2.tar.xz
cd linux-5.19.2
make mrproper
make defconfig
make -j$(nproc)
make modules_install
cp -v arch/x86/boot/bzImage /boot/vmlinuz-5.19.2-lfs-11.2-systemd
cp -v System.map /boot/System.map-5.19.2
cp -v .config /boot/config-5.19.2
cd ..
rm -rf linux-5.19.2

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda3      /            ext4    defaults            1     1
/dev/sda1      /boot        ext4    defaults            1     2
/dev/sda2      swap         swap    pri=1               0     0

# End /etc/fstab
EOF

# Установка системного времени
ln -sfv /usr/share/zoneinfo/your_region(for example, Europe)/your_city(for example, Berlin) /etc/localtime

localedef -i en_US -f UTF-8 en_US.UTF-8

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

echo "lfs" > /etc/hostname

# Создание файла /etc/hosts
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

Wonderful, your operating system is now LFS!
...and now I advise you to go outside and touch the grass.

now all we have to do is clean up the system, perform backups, disable virtual file systems, disable the LFS file system, reboot, make a password, check the network, make a user, unmount partitions and synchronize time

rm -rf /tmp/*
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libfl_pic.a
rm -f /usr/lib/libz.a

cd /
tar -cJpf $HOME/lfs-temp-tools-11.2-systemd.tar.xz .

umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/proc
umount -v $LFS/sys
umount -v $LFS/run

umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/proc
umount -v $LFS/sys
umount -v $LFS/run

umount -v $LFS

shutdown -h now

passwd root #create password
useradd -m -G users,wheel,audio,video -s /bin/bash username
passwd ... #your username

#if you downloaded sudo
visudo

#uncomment the line:
%wheel ALL=(ALL) ALL

#updating information about libraries:
ldconfig

#checking the system version:
cat /etc/lfs-release

#checking the network operation:
ping -c 3 google.com

#time synchronization:
hwclock --systohc

Additional recommendations:

Install additional software of your choice (for example, a text editor, a web browser).
Configure the graphical environment, if necessary (X.Org , window manager or desktop environment).
Update the system regularly by compiling and installing new versions of packages.
Create a bootable USB drive with your LFS system for use on real hardware.
Review the documentation of the Linux From Scratch project for further configuration and optimization of your system.

Keep in mind that LFS is a minimalistic system, and you may need to install additional tools and utilities for everyday use.
Your LFS system should now be fully functional and ready to use. Congratulations on successfully creating your own Linux system from scratch!
