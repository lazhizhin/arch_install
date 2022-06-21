## My arch installation scripts
This scripts are intended for personal use only.

If you are a newbie like me, thinking about cloning this repo and running `./install.sh` in your terminal, **reconsider**.
With that in mind, you can read through code and maybe borrow something, when building your own install script.

If you are an advanced linux chad, no matter how you landed here, feel free to rant at me for doing everything wrong.
I would appreciate any comments/suggestions.

## How it works
User runs `install.sh`, which receives the following parameters:
- `-b` for boot option, either **single** or **dual**
- `-p` for CPU, either **intel** or **amd** (no check)
- `-g` for GPU, either of **intel**, **amd** or **nvidia** (no check)
- `-u` for user name, by default **lyonya**
- `-h` for host name, by default **large**
- `-l` - dummy for laptop, **1** if machine is laptop, **0** otherwise. This variable is then used to set other parameters for my machines.

First, `install.sh` passes boot option to `partitioning.sh`, that creates partitions (as name suggests) with `gdisk`.
Root partition is always 40GB and home partition always takes the rest of the space.
EFI partition is only created with single boot option, otherwise Windows EFI is mounted at `/mnt/boot`

After partitioning is done, `base.sh` is executed on `/mnt` as root.
Basically, this scripts contains all commands, that should be run as root.
When this script is run, it will prompt user for password, that will be set for both regular user and root.

Once `base.sh` is finished, `config.sh` is invoked as regular user.
It installs AUR and pip packages, downloads wallpaper and sets [my dotfiles](https://github.com/lyo-nya/.files).

When `config.sh` is done, disks are umounted and machine is rebooted.
User should be logged in automatically on tty1, this behaviour is set in `base.sh`.
On first zsh launch, user will be asked to connect to the internet, so that all antigen bundles can be installed.
Packages for [`neovim`](https://neovim.io/) also won't be installed out of the box, so one needs to run `:PackerInstall` and `:PackerUpdate`, and then restart editor.

### TODO
- [ ] Replace *synaptics* with *libinput* as [Arch wiki](https://wiki.archlinux.org/title/Touchpad_Synaptics) suggests
- [ ] Fix AUR packages installation
- [ ] Fix R libraries installation
