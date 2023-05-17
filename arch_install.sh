#!/bin/bash
#очитска mnt


umount -l /mnt/*
umount -l /mnt
umount -l /mnt/boot/efi
rm -rf /mnt/*
#Создание разделов sdaumount -l /mnt
(echo o; sleep 1; echo  w) | fdisk /dev/sda
(echo n; echo p; echo 1; echo ''; echo +1024M; sleep 1; echo w) | fdisk /dev/sda
(echo n; echo p; echo 2; echo ''; echo ''; sleep 1; echo w) | fdisk /dev/sda
(echo a; echo  1; sleep 1; echo w) | fdisk /dev/sda
#Форматирование дисков'
mkfs.vfat -F32 /dev/sda1
mkfs.btrfs -f -L 'root' /dev/sda2

sed -i s/'#en_US.UTF-8'/'en_US.UTF-8'/g /etc/locale.gen
sed -i s/'#ru_RU.UTF-8'/'ru_RU.UTF-8'/g /etc/locale.gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'KEYMAP=ru' > /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf
setfont cyr-sun16
locale-gen >/dev/null 2>&1; RETVAL=$?

#Монтирование дисков'
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
umount /mnt

#mkdir /mnt/{boot,home,.snapshots}
#mkdir -p /mnt/{boot,home,.snapshots}

mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,ssd,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{home,.snapshots}
mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,ssd,subvol=@home /dev/sda2 /mnt/home
mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,subvol=@snapshots  /dev/sda2 /mnt/.snapshots
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi


# Установка 
sed -i s/'#ParallelDownloads = 5'/'ParallelDownloads = 13'/g /etc/pacman.conf
reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy
pacstrap -i /mnt base base-devel  linux  linux-firmware reflector --noconfirm 

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "sed -i s/'#Color'/'Color'/g /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Moskow /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
arch-chroot /mnt /bin/bash -c "sed -i s/'#en_US.UTF-8'/'en_US.UTF-8'/g /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "sed -i s/'#ru_RU.UTF-8'/'ru_RU.UTF-8'/g /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf"
arch-chroot /mnt /bin/bash -c "echo 'KEYMAP=ru' > /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo 'FONT=cyr-sun16' >> /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo 'KAGAMI' > /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo '127.0.0.1 localhost' > /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo '::1       localhost' >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo '127.0.0.1 kagami.localdomain kagami' >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers"

echo 'Создаем root пароль'
echo -n "Enter root password: "
read root_password
arch-chroot /mnt /bin/bash -c "echo 'root:$root_password' | chpasswd" 
# echo 'Создаем пользователя'
echo -n "Enter user name: "
read username
arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash $username"
echo -n "Enter user password: "
read user_password
arch-chroot /mnt /bin/bash -c "echo '$username:$user_password' | chpasswd" 
arch-chroot /mnt /bin/bash -c "sed -i s/'#ParallelDownloads = 5'/'ParallelDownloads = 16'/g /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist"
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"
arch-chroot /mnt /bin/bash -c "pacman -S grub efibootmgr ntfs-3g os-prober btrfs-progs vim dhcpcd net-tools networkmanager alsa-utils nvidia nvidia-settings xorg-server xorg-xinit mc htop bash-completion tmux mc openssh  --noconfirm"
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"
arch-chroot /mnt /bin/bash -c "systemctl enable sshd.service"
#arch-chroot /mnt /bin/bash -c "mkdir /boot/efi"
arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id='Arch'"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
#umount -R /mnt
