#!/bin/bash
tell() {
  echo -e "\033[0;33m|-- ${*}\033[0m"
  $* || {
    echo -e "\033[0;31mFail !\033[0m" 1>&2 ;
    exit 1 ;
  }
}

explain() {
  echo -e "\033[0;34m${1}\033[0m"
}

success() {
  echo -e "\033[0;32m${1}\033[0m"
}

explain "Configuration System"
tell export LANG=de_DE.UTF-8
tell echo $LANG UTF-8 >> /etc/locale.gen
tell echo de_DE ISO-8859-1 >> /etc/locale.gen
tell echo de_DE@euro ISO-8859-15 >> /etc/locale.gen
tell echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
tell locale-gen
tell echo LANG=$LANG > /etc/locale.conf
tell echo LC_TIME=$LANG >> /etc/locale.conf
tell echo LC_COLLATE=C >> /etc/locale.conf
tell echo LANGUAGE=de_DE >> /etc/locale.conf
tell echo KEYMAP=de-latin1 > /etc/vconsole.conf
tell ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
tell hwclock --systohc
tell echo dev-monster > /etc/hostname
tell systemctl enable dhcpcd.service
tell passwd

explain "Set your mkinitcpio encrypt/lvm2 hooks and rebuild."
tell sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)/' /etc/mkinitcpio.conf
tell mkinitcpio -p linux

explain "Add a keyfile to decrypt the root volume and properly set the hooks"
tell dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
tell cryptsetup luksAddKey /dev/sda1 /crypto_keyfile.bin
tell chmod 000 /crypto_keyfile.bin
tell sed -i 's/^FILES=.*/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
tell mkinitcpio -p linux

explain "Configure GRUB and Set the UUID of the encrypted root device"
tell echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub
tell ROOTUUID=$(blkid /dev/sda1 | awk '{print $2}' | cut -d '"' -f2)
tell sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID="$ROOTUUID":lvm:allow-discards resume=\/dev\/mapper\/arch-swap\"/" /etc/default/grub
tell grub-install /dev/sda
tell grub-mkconfig -o /boot/grub/grub.cfg
tell chmod -R g-rwx,o-rwx /boot

explain "Exit"
tell exit