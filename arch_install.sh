linux, [17.05.2023 1:00]
#bash #arch 

#!/bin/bash

echo " 
Скрипт для kagami uefi systemdboot
диск разбит cfdisk
sda
sda1 efi 512MiB
sda2 root 55G
#sda3 dumproot 55G
#sda4 swap 1G
"
sed -i s/'#en_US.UTF-8'/'en_US.UTF-8'/g /etc/locale.gen
sed -i s/'#ru_RU.UTF-8'/'ru_RU.UTF-8'/g /etc/locale.gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'KEYMAP=ru' > /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf
setfont cyr-sun16
locale-gen >/dev/null 2>&1; RETVAL=$?

#cfdisk -z /dev/sda

#Форматирование дисков'
mkfs.vfat -F32 /dev/sda1
mkfs.btrfs -f -L 'root' /dev/sda2

#mkfs.btrfs -f -L 'dumproot' /dev/sda3
#mkswap /dev/sda4
#swapon /dev/sda4


#Монтирование дисков'
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
#btrfs su cr /mnt/@var
#btrfs su cr /mnt/@var_log
btrfs su cr /mnt/@snapshots
umount /mnt

#mkdir /mnt/{boot,home,var,var_log,.snapshots}
mkdir /mnt/{boot,home,.snapshots}
mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,ssd,subvol=@ /dev/sda2 /mnt
mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,ssd,subvol=@home  /dev/sda2  /mnt/home
#mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,subvol=@var  /dev/sda2  /mnt/var
#mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,subvol=@var_log /dev/sda2 /mnt/var_log
mount -o rw,noatime,compress=lzo,space_cache=v2,discard=async,subvol=@snapshots  /dev/sda2 /mnt/.snapshots
#mkdir /mnt/boot
mount /dev/sda1 /mnt/boot    

# Установка 

#sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
#sed -i s/'#ParallelDownloads = 5'/'ParallelDownloads = 5'/g /etc/pacman.conf
#sed -i s/'#VerbosePkgLists'/'VerbosePkgLists'/g /etc/pacman.conf
#sed -i s/'#Color'/'ILoveCandy'/g /etc/pacman.conf


pacman -Syy
#zen
pacstrap -i /mnt base base-devel linux  linux-firmware --noconfirm 
# linux  linux-firmware intel-ucode btrfs-progs vim dhcpcd net-tools networkmanager    

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Moskow /etc/localtime"
#arch-chroot /mnt /bin/bash -c "timedatectl set-timezone Europe/Moskow"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
arch-chroot /mnt /bin/bash -c "sed -i s/'#en_US.UTF-8'/'en_US.UTF-8'/g /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "sed -i s/'#ru_RU.UTF-8'/'ru_RU.UTF-8'/g /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf"
arch-chroot /mnt /bin/bash -c "echo 'KEYMAP=ru' > /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo 'FONT=cyr-sun16' >> /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo 'KAGAMI' > /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo '127.0.0.1 localhost' > /etc/hosts"
#arch-chroot /mnt /bin/bash -c "echo '::1       localhost' >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo '127.0.0.1 kagami.localdomain kagami' >> /etc/hosts"
#arch-chroot /mnt /bin/bash -c "sed -i s/'#ParallelDownloads = 5'/'ParallelDownloads = 16'/g /etc/pacman.conf"
#arch-chroot /mnt /bin/bash -c "sed -i s/'#VerbosePkgLists'/'VerbosePkgLists'/g /etc/pacman.conf"
#arch-chroot /mnt /bin/bash -c "sed -i s/'#Color'/'ILoveCandy'/g /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers"

echo 'Создаем root пароль'
echo -n "Enter root password: "
read root_password
arch-chroot /mnt /bin/bash -c "echo 'root:$root_password' | chpasswd" 

echo 'Создаем пользователя'
echo -n "Enter user name: "
read username
arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash $username"
echo -n "Enter user password: "
read user_password
arch-chroot /mnt /bin/bash -c "echo 'username:$user_password_password' | chpasswd" 
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

pacman -S grub efibootmgr ntfs-3g os-prober btrfs-progs vim dhcpcd net-tools networkmanager alsa-utils nvidia nvidia-settings xorg xorg-server xorg-xinit 

arch-chroot /mnt /bin/bash -c "reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist"
arch-chroot /mnt /bin/bash -c "mkdir /boot/efi"
arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Arch Linux""
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"

#arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash media"
#echo 'Создаем media пароль'
#passwd media

linux, [17.05.2023 1:00]
arch-chroot /mnt /bin/bash -c "bootctl install --path=/boot"  
arch-chroot /mnt /bin/bash -c "echo 'default arch' >> /boot/loader/loader.conf"
arch-chroot /mnt /bin/bash -c "echo 'timeout 1' >> /boot/loader/loader.conf"
arch-chroot /mnt /bin/bash -c "echo 'title Arch Linux' >> /boot/loader/entries/arch.conf"
arch-chroot /mnt /bin/bash -c "echo 'linux  /vmlinuz-linux' >> /boot/loader/entries/arch.conf"
arch-chroot /mnt /bin/bash -c "echo 'initrd /intel-ucode.img' >> /boot/loader/entries/arch.conf"
arch-chroot /mnt /bin/bash -c "echo 'options root="LABEL=root" rw' >> /boot/loader/entries/arch.conf"
arch-chroot /mnt /bin/bash -c "echo 'options resume="LABEL=swap"' >> /boot/loader/entries/arch.conf"



#intel
#pacstrap -i /mnt mesa mesa-demos lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader network-manager-applet libva-intel-driver lib32-libva-intel-driver --noconfirm

pacman -Syy --noconfirm

reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist


#amd-ucode xf86-video-amdgpu sddm sddm-kcm firefox bluez bluez-utils kmix discover cups
#systemctl enable sddm --force


arch-chroot /mnt /bin/bash -c "exit"
umount -R /mnt



reboot