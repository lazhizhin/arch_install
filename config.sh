#!/bin/sh

export GOPATH="$HOME/.local/share/go"

# Clear user home directory from bash dotfiles
rm $HOME/.bash*

# Install paru
git clone https://aur.archlinux.org/paru.git tmp

# Build package
cd tmp && makepkg --noconfirm -s

# Install paru from prebuild files
# The problem is that makepkg -i does not ask for password via standard input.
# I guess it can be fixed with PACMAN_AUTH parameter, but I couldnt' get it working
sudo -S pacman -U *.pkg.tar.*
cd $HOME
rm -rf tmp

# Install AUR packages
AUR_PKGS=(
    # File manager
    "lf"
    # Neovim ( text editor )
    "neovim-git"
    # Font for terminal ( alacritty )
    "nerd-fonts-jetbrains-mono"
    # Package manager for neovim
    "nvim-packer-git"
)

# Identify keyboard I'm running
KBD=$(cat /sys/class/dmi/id/product_name)

# Install tool, that disables keyboard backlight
[[ "$KBD" == "MS-7C94" ]] && AUR_PKGS+=(g810-led-git)

# Install packages
# sudoflags are used to force sudo to read password from standard input
paru -S --sudoflags "-S" "${AUR_PKGS[@]}"
# For some reason, packages fail to install first time
paru -S --sudoflags "-S" "${AUR_PKGS[@]}"

# Install pip
python -m ensurepip --upgrade

# Upgrade pip
python -m pip install --upgrade pip

# Formatter for lua
luarocks install --local --server=https://luarocks.org/dev luaformatter

# Python packages, yapf and isort are formatters
.local/bin/pip install yapf isort

# Linter for yaml
.local/bin/pip install yamllint

# Install lua language server
LUAPATH=$HOME/.local/share/lua-language-server
git clone https://github.com/sumneko/lua-language-server $LUAPATH
cd $LUAPATH && git submodule update --init --recursive
cd 3rd/luamake && ./compile/install.sh
cd ../..
./3rd/luamake/luamake rebuild


# EFM language server
go install github.com/mattn/efm-langserver@latest

# Download wallpaper
mkdir $HOME/Pictures
curl https://raw.githubusercontent.com/elementary/wallpapers/master/backgrounds/Canazei%20Granite%20Ridges.jpg -o $HOME/Pictures/wallpaper.jpg

# Get my dotfiles from github
git clone --bare https://github.com/lyo-nya/.files.git $HOME/.files

# Create alias for managing dotfiles
function config {
    /usr/bin/git --git-dir=$HOME/.files/ --work-tree=$HOME $@
}

# Pull dotfiles
config checkout
config config status.showUntrackedFiles no

# Install R language server
mkdir -p ~/.cache/R/library
export R_PROFILE_USER="$HOME/.config/R/.Rprofile"
Rscript -e "install.packages('languageserver', dependencies=TRUE)"
