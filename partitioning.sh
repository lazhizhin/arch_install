#!/bin/zsh

# List disks for user
lsblk

# Ask for disk to partition
read "?Disk to partition: " DISK_TO_PARTITION

# Command to clean partition table
CLEAN_TABLE_CMD=("o", "y")

# Comamnds to create EFI partition with size 512M
EFI_PARTITION_CMD=("n" "" "" "+512M" "ef00")

# Commands to create root partition with size 40G
ROOT_PARTITION_CMD=("n" "" "" "+40G" "")

# Commands to create home partition, that takes the rest of the disk
HOME_PARTITION_CMD=("n" "" "" "" "")

# Single boot
if [ "$1" = "single" ];
then
    # Partitioning commands
    PARTITIONING_COMMANDS=(
        "${CLEAN_TABLE_CMD[@]}"
        "${EFI_PARTITION_CMD[@]}"
        "${ROOT_PARTITION_CMD[@]}"
        "${HOME_PARTITION_CMD[@]}"
        "w"
        "y"
    )
    # Partition disk with gdisk
    printf '%s\n' "${PARTITIONING_COMMANDS[@]}" | gdisk /dev/$DISK_TO_PARTITION
    EFI_PARTITION=/dev/"$DISK_TO_PARTITION"p1
    ROOT_PARTITION=/dev/"$DISK_TO_PARTITION"p2
    HOME_PARTITION=/dev/"$DISK_TO_PARTITION"p3
    # Format EFI partition
    mkfs.vfat $EFI_PARTITION
    
# Dual boot
elif [ "$1" = "dual" ];
then
    # List partitions, that are already present
    PARTITIONS=$(lsblk -l -o NAME,PARTTYPENAME | grep $DISK_TO_PARTITION)
    # Save EFI partition path
    EFI_PARTITION=/dev/$(echo "$PARTITIONS" | grep EFI | cut -f1 -d" ")
    # Save Linux partitions
    LINUX_PARTITIONS=$(echo "$PARTITIONS" | grep Linux | cut -f1 -d" ")
    # If there are any Linux partitions, delete them
    if ! [[ -z "$LINUX_PARTITIONS" ]];
    then
        # Get partition numbers
        PARTITIONS_TO_CLEAR=$(echo "$LINUX_PARTITIONS" | awk -F"$DISK_TO_PARTITION"p '{ print $2 }')
        # Convert to array
        PARTITIONS_TO_CLEAR=("${(@f)$(echo $PARTITIONS_TO_CLEAR)}")
        # Delete partitions
        CLEAR_CMDS=$(printf "d\n%s\n" "${PARTITIONS_TO_CLEAR[@]}")
        echo "$CLEAR_CMDS \nw\ny\n" | gdisk /dev/$DISK_TO_PARTITION
    fi
    # Create root and home partition, no need to create EFI partition,
    # since it is shared with windows
    PARTITIONING_COMMANDS=(
        "${ROOT_PARTITION_CMD[@]}"
        "${HOME_PARTITION_CMD[@]}"
        "w"
        "y"
    )
    printf '%s\n' "${PARTITIONING_COMMANDS[@]}" | gdisk /dev/$DISK_TO_PARTITION
    # EFI + 3 Windows partitions => new partitions start with 5
    ROOT_PARTITION=/dev/"$DISK_TO_PARTITION"p5
    HOME_PARTITION=/dev/"$DISK_TO_PARTITION"p6
fi

# Format filesystem
mkfs.ext4 $ROOT_PARTITION
mkfs.ext4 $HOME_PARTITION

# Mount partitions
mount $ROOT_PARTITION /mnt
mkdir /mnt/home
mount $HOME_PARTITION /mnt/home
mkdir -p /mnt/boot
mount $EFI_PARTITION /mnt/boot

# Delete linux boot files, if they already exist
find /mnt/boot| grep -v 'Microsoft' | xargs rm -rf
