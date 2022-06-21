#!/bin/sh

# Read options
while getopts b:p:g:u:h:l: flag; do
    case "${flag}" in
        b) BOOT_OPT=${OPTARG} ;;
        p) PROCESSOR=${OPTARG} ;;
        g) GRAPHICS=${OPTARG} ;;
        u) USR=${OPTARG} ;;
        h) HOST=${OPTARG} ;;
        l) ISLAPTOP=${OPTARG} ;;
    esac
done

# My configurations
if [ "$ISLAPTOP" -eq 1 ];
then
    BOOT_OPT=single
    PROCESSOR=intel
    GRAPHICS=intel
elif [ "$ISLAPTOP" -eq 0 ];
then
    BOOT_OPT=dual
    PROCESSOR=amd
    GRAPHICS=nvidia
else
    exit
fi

# Default parameters
[ -z "$USR" ] && USR=lyonya
[ -z "$HOST" ] && HOST=large

# Update packages
pacman -Sy

# Syncronize time
timedatectl set-ntp true

# Partition drive
ALLOWED_BOOT_OPTS=(single dual)
if [[ ${ALLOWED_BOOT_OPTS[*]} =~ ${BOOT_OPT} ]]; then
    ./partitioning.sh $BOOT_OPT
else
    echo "Unknown boot option $BOOT_OPT, pick one of {single, dual}"
    exit
fi

# packages to pacstrap
BASE=(base base-devel zsh linux linux-firmware git)

# Add ucode
[ "$PROCESSOR" == "intel" ] && BASE+=(intel-ucode)
[ "$PROCESSOR" == "amd" ] && BASE+=(amd-ucode)

# Graphics drivers
[ "$GRAPHICS" == "nvidia" ] && BASE+=(nvidia nvidia-utils nvidia-settings)
[ "$GRAPHICS" == "intel" ] && BASE+=(xf86-video-intel)
[ "$GRAPHICS" == "amd" ] && BASE+=(xf86-video-amdgpu)

# Install essential packages
pacstrap /mnt ${BASE[@]}

# Generate file system table
genfstab -U /mnt >>/mnt/etc/fstab

# Copy scripts, that should be executed next to /mnt, since original /root won't
# be accessible. Some day I will find out, how to avoid this
cp base.sh config.sh /mnt

# Execute base installation script as root
arch-chroot /mnt ./base.sh $USR $HOST $ISLAPTOP $BOOT_OPT

# Execute config script as specified user
arch-chroot /mnt runuser $USR -c "sh /config.sh"

# Remove scripts
rm /mnt/base.sh /mnt/config.sh

# Reboot
umount -a
reboot
