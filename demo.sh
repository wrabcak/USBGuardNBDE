#!/usr/bin/env sh
# Copyright (C) 2023 Lukas Vrabec, <lvrabec@redhat.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

echo "
Purpose of the demo is to demonstrate basic functionality of USBGuard to block USB devices which are not allowed by the generated USBGuard allow policy rules. Then, encrypt the USB device via luks and demonstrate file pin to decrypt the device only when metadata are available.
"

# root priviledges required
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install all required packages
yum install -y git meson ninja-build usbguard cryptsetup 2> /dev/null

# prepare env for demo
git config --global http.sslVerify false
git clone https://github.com/cbiedl/clevis.git
cd clevis
git checkout template-file-pin
dnf builddep clevis -y
meson setup build
ninja -C build -j$(nproc)
ninja -C build install

mkdir /mnt/mount

# start demo
echo ""
echo "Demo start"
echo ""

read -p "remove the USB device"
echo ""
echo ""

read -p "lsusb"
echo ""
lsusb
echo ""

read -p "lsblk"
echo ""
lsblk
echo ""

read -p "cat /etc/usbguard/usbguard-daemon.conf  | grep Implicit"
echo ""
cat /etc/usbguard/usbguard-daemon.conf  | grep Implicit
echo ""

read -p "usbguard generate-policy > rules.conf"
echo ""
usbguard generate-policy > rules.conf
echo ""

read -p "cat rules.conf"
echo ""
cat rules.conf
echo ""

read -p "install -m 0600 -o root -g root rules.conf /etc/usbguard/rules.conf"
echo ""
install -m 0600 -o root -g root rules.conf /etc/usbguard/rules.conf
echo ""

read -p "systemctl restart usbguard"
echo ""
systemctl restart usbguard
echo ""

read -p "insert USB device!"
echo ""
echo ""

read -p "lsusb"
echo ""
lsusb
echo ""

read -p "lsblk"
echo ""
lsblk
echo ""

read -p "usbguard generate-policy > rules.conf"
echo ""
usbguard generate-policy > rules.conf
echo ""

read -p "cat rules.conf"
echo ""
cat rules.conf
echo ""

read -p "install -m 0600 -o root -g root rules.conf /etc/usbguard/rules.conf"
echo ""
install -m 0600 -o root -g root rules.conf /etc/usbguard/rules.conf
echo ""

read -p "systemctl restart usbguard"
echo ""
systemctl restart usbguard
echo ""

read -p "lsblk"
echo ""
lsblk
echo ""

read -p "cat /etc/usbguard/rules.conf"
echo ""
cat /etc/usbguard/rules.conf
echo ""

read -p "mount /dev/sda /mnt/mount"
echo ""
mount /dev/sda /mnt/mount
echo ""

read -p "ls /mnt/mount"
echo ""
ls /mnt/mount
echo ""

read -p "umount /mnt/mount"
echo ""
umount /mnt/mount
echo ""

read -p "cryptsetup luksFormat /dev/sda"
echo ""
cryptsetup luksFormat /dev/sda
echo ""

read -p "cryptsetup luksOpen /dev/sda secret"
echo ""
cryptsetup luksOpen /dev/sda secret
echo ""

read -p "mkfs.ext4 /dev/mapper/secret"
echo ""
mkfs.ext4 /dev/mapper/secret
echo ""

read -p "mount /dev/mapper/secret /mnt/mount/"
echo ""
mount /dev/mapper/secret /mnt/mount/
echo ""

read -p "ls /mnt/mount"
echo ""
ls /mnt/mount
echo ""

read -p "umount /mnt/mount"
echo ""
umount /mnt/mount
echo ""

read -p "cryptsetup luksClose /dev/mapper/secret"
echo ""
cryptsetup luksClose /dev/mapper/secret
echo ""

read -p "clevis luks bind -d /dev/sda file '{"name":"/tmp/metadata.txt"}'"
echo ""
clevis luks bind -d /dev/sda file '{"name":"/tmp/metadata.txt"}'
echo ""

read -p "cat /tmp/metadata.txt"
echo ""
cat /tmp/metadata.txt
echo ""

read -p "clevis luks unlock -d /dev/sda -n secret"
echo ""
clevis luks unlock -d /dev/sda -n secret
echo ""

read -p "mount /dev/mapper/secret /mnt/mount/"
echo ""
mount /dev/mapper/secret /mnt/mount/
echo ""

read -p "ls /mnt/mount"
echo ""
ls /mnt/mount
echo ""

read -p "umount /mnt/mount"
echo ""
umount /mnt/mount
echo ""

read -p "cryptsetup luksClose /dev/mapper/secret"
echo ""
cryptsetup luksClose /dev/mapper/secret
echo ""

read -p "mv /tmp/metadata.txt /root"
echo ""
mv /tmp/metadata.txt /root
echo ""

read -p "clevis luks unlock -d /dev/sda -n secret"
echo ""
clevis luks unlock -d /dev/sda -n secret
echo ""

read -p "mount /dev/mapper/secret /mnt/mount/"
echo ""
mount /dev/mapper/secret /mnt/mount/
echo ""

read -p "mv /root/metadata.txt /tmp"
echo ""
mv /root/metadata.txt /tmp
echo ""

read -p "clevis luks unlock -d /dev/sda -n secret"
echo ""
clevis luks unlock -d /dev/sda -n secret
echo ""

read -p "mount /dev/mapper/secret /mnt/mount/"
echo ""
mount /dev/mapper/secret /mnt/mount/
echo ""

echo "Demo end."
echo "Clean up phase."

# clean up phase

umount /mnt/mount
cryptsetup luksClose /dev/mapper/secret

systemctl stop usbguard
rm -rf /etc/usbguard/rules.conf

git config --global http.sslVerify true

rm -rf clevis

rm -rf /mnt/mount /root/rules.conf
rm -rf /usr/local/bin/clevis*
rm -rf /usr/local/etc/xdg/autostart/clevis-luks-udisks2.desktop
rm -rf /usr/local/libexec/clevis*
rm -rf /usr/local/share/man/man1/clevis*
rm -rf /usr/local/share/man/man7/clevis*
