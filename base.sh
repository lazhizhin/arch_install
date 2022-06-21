#!/bin/sh

# Set timezone and syncronize
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Generate locales
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
echo "LANG=en_US.UTF-8" >>/etc/locale.conf
locale-gen

# Hostname configuration
echo "$2" >>/etc/hostname
echo "
127.0.0.1 localhost
::1       localhost
127.0.1.1 $2.localdomain $2" >>/etc/hosts

# Install packages from arch repository
PACMAN_PKGS=(
    # Basic packages
    "linux-headers"
    "base-devel"
    "npm"
    "sudo"
    "grub"
    "ninja"
    "networkmanager"
    "openssh"
    # Programming languages
    "go"
    "r"
    # Audio
    "pulseaudio"
    "alsa-utils"
    "pulseaudio-alsa"
    # X11
    "xorg"
    "xorg-xinit"
    # Fonts
    "ttf-ibm-plex" # For qtile (window manager)
    "noto-fonts"   # For glyphs
    # Dependencies
    "ripgrep" # For nvim-telescope
    "fd"
    "cargo" # For paru (AUR helper)
    # Programmes
    "exa"              # Alternative ls
    "alacritty"        # Terminal emulator
    "chromium"         # Web browser
    "qtile"            # Window manager
    "telegram-desktop" # Messenger
    # Utilities
    "xclip"     # Clipboard
    "libsecret" # Keyring
    "gnome-keyring"
    "transmission-gtk" # Torrent client
    "sxiv"             # Image viewer
    "mpv"              # Video player
    "cbatticon"        # Battery icon
    "volumeicon"       # Volume icon
    "flameshot"        # Screenshots
    # Formatters and checkers
    "shellcheck" # Bash checker
    "shfmt"      # Bash formatter
    # Archivers
    "unzip"
    "p7zip"
    "unrar"
    # Other dependencies
    "luarocks"
    "efibootmgr"
    "jsoncpp"
    "rhash"
    "cmake"
    "gperf"
    "libluv"
    "lua51"
    "lua51-mpack"
    "lua51-lpeg"
    "libuv"
    "unibilium"
    "libtermkey"
    "msgpack-c"
    "tree-sitter"
)

# Install packages
pacman -S --noconfirm "${PACMAN_PKGS[@]}"


# Python type checker
npm i -g pyright

# HTML and CSS formatter
npm i -g --save-dev --save-exact prettier

# JS linter and formatter
npm i -g eslint

# Configure synaptics touchpad driver
if [ "$3" -eq 1 ]; then
    pacman -S --noconfirm xf86-input-synaptics
    touch /etc/X11/xorg.conf.d/70-synaptics.conf
    echo '
    Section "InputClass"
    Identifier "touchpad"
    Driver "synaptics"
    MatchIsTouchpad "on"
        Option "TapButton1" "1"
        Option "TapButton2" "3"
        Option "TapButton3" "2"
        Option "VertEdgeScroll" "on"
        Option "VertTwoFingerScroll" "on"
        Option "HorizEdgeScroll" "on"
        Option "HorizTwoFingerScroll" "on"
        Option "CircularScrolling" "on"
        Option "CircScrollTrigger" "2"
        Option "EmulateTwoFingerMinZ" "40"
        Option "EmulateTwoFingerMinW" "8"
        Option "CoastingSpeed" "0"
        Option "FingerLow" "30"
        Option "FingerHigh" "50"
        Option "MaxTapTime" "125"
        Option "VertScrollDelta" "-111"
        Option "HorizScrollDelta" "-111"
        Option "PalmDetect" "1"
        Option "PalmMinWidth" "1"
        Option "PalmMinZ" "1"
    EndSection' >>/etc/X11/xorg.conf.d/70-synaptics.conf
fi

# Enable os-prober when dual booting
if [[ "$4" == "dual" ]]; then
    pacman -S --noconfirm os-prober
    echo "GRUB_DISABLE_OS_PROBER=false" >>/etc/default/grub
fi

# Ask for password (assuming it should be the same for root and user)
read -p "Set password: " -s pass

# Set user
useradd -m -s /bin/zsh "$1"

# Set password
echo "root:$pass" | chpasswd
echo "$1:$pass" | chpasswd

# Make user sudoer
echo "$1 ALL=(ALL) ALL" >>"/etc/sudoers.d/$1"

# Install grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Autologin at tty1
TTY1_GETTY_DIR=/etc/systemd/system/getty@tty1.service.d
mkdir $TTY1_GETTY_DIR
echo "
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $1 --noclear %I \$TERM
" >>$TTY1_GETTY_DIR/override.conf

# Enable services
systemctl enable getty@tty1.service
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable systemd-timesyncd
