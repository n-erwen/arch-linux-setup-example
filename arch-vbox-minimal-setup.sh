#!/bin/zsh

echo "Please enter the desired keyboard mapping from the following keymaps:"
echo "(Press any key to continue...)"; read -k1 -s
ls /usr/share/kbd/keymaps/**/*.map.gz | xargs -n1 basename | sed 's/\.map.gz$//' | column -x | less
read "?(Please enter your desired keymap) >> " KEYMAP
loadkeys $KEYMAP
echo "\n\tCurrent key mapping: $KEYMAP\n"
read -k1 -s "?(Press any key to continue...)"

ls /sys/firmware/efi/efivars # if this does not exist then you are in BIOS mode

echo ""
ip link # check your network interface is enabled
echo "(Please enter your network interface out of the ones above.)"
echo "(It should be labelled BROADCAST)"
read "?>> " NETWORK_INTERFACE
dhcpcd $NETWORK_INTERFACE
# test the network connection w/ ping command
echo "\nTesting network connection...
ping -c 10 www.google.com
read -k1 -s "?(Press any key to continue...)"

echo "\nEnabling time synchronisation..."
timedatectl set-ntp true # enable time synchronisation
timedatectl status

#IGNORE
fdisk -l
fdisk /dev/sda
    # example partition table layout for a 20GB hard disk:
    g  # create a new empty GPT partition table
    n 1 2048 4096 (1 MiB)
    t 1 4 (BIOS Boot)
    n 2 6144 41949184 (20 MiB)
    t 2 24 (Linux root (x86-64))
    n 3 41951232 50331614 (4 GiB)
    t 3 19 (Linux swap)
    w # save changes

parted /dev/sda mklabel gpt
parted /dev/sda unit MiB mkpart primary 1MiB 2MiB
parted /dev/sda set 1 bios_grub on 
parted /dev/sda unit MiB mkpart primary ext4 2MiB 20GiB parted /dev/sda unit MiB mkpart primary linux-swap 20480MiB 100%
fdisk -l

mkfs.ext4 /dev/sda2
mkswap /dev/sda3

mount /dev/sda2 /mnt
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

pacman -Syu vim nano
nano /etc/locale.gen # install nano first (pacman -S nano) and then edit /etc/locale.gen (uncomment the locales you need)
locale-gen

pacman -Syu sudo polkit git python dhcpcd man-db man-pages zip unzip tar gzip

echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf
echo "natasha-arch-X" > /etc/hostname # insert your hostname into the file
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tnatasha-arch-X.localdomain\tnatasha-arch-X" > /etc/hosts

passwd root # set the root passwd

useradd natasha -r -m # -r creates system user, -m creates home dir
passwd natasha

visudo

pacman -S grub
grub-install --target=i386-pc /dev/sda

#enable microcodes for Intel CPU
pacman -S intel-ucode
CONFIG_BLK_DEV_INITRD=Y
CONFIG_MICROCODE=Y
CONFIG_MICROCODE_INTEL=Y
CONFIG_MICROCODE_AMD=Y
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable dhcpcd.service

exit # exit chroot environment
umount -R /mnt
shutdown now # or reboot
# remove installation media