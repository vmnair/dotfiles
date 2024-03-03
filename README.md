# dotfiles
## Checklist For Installation:
- [ ] Debian Installation
    - [ ] Programs that need to be installed post-Debian install.
    - [ ] Screen Resolution and Layout
- [x] Wifi Card Setup
- [x] Install and [setup Alacritty](https://www.behova.net/fonts-in-alacritty/)
- [x] Neovim Installation & Setup
    - [ ] lazy.nvim
    - [ ] lazy.git
- [x] [Installing getnf and fonts](https://linuxtldr.com/install-fonts-on-linux/)
- [ ] i3 Windows Manager Installation & Setup
- [ ] Rofi Menu Manger & PICOM Compositor Installation.
- [ ] [Enabling click on tap]
1. Debian installation.
    - [Official Debian Site for Installation of MacBook Pro](https://wiki.debian.org/MacBookPro)
    - See installation info [here](https://www.mail-archive.com/debian-user@lists.debian.org/msg773640.html).
    - Reboot the MacBook while holding the `Alt` button to reach the boot screen.
      
    The following programs need to be installed:
   
        - XFCE
        - Firefox
        - Alacritty
        - git
        - Rofi
        - zsh
        - Neovim
        - tree
        - nitrogen
        - picom
   
3. WiFi
    1. MacBook Pro:

        a. Use `lspci` on the terminal to list the PCI devices

        c. The interface name is `wlp3s0`.

       d. See Details of the driver installation: [WiFi Driver Installation](https://unix.stackexchange.com/questions/175810/how-to-install-broadcom-bcm4360-on-debian-on-macbook-pro).
       
       e. wl driver needed for `bcm4360` [wl](https://wiki.debian.org/wl)

4. iSight Camera Not working:
    - [iSight Driver Issue](https://forums.linuxmint.com/viewtopic.php?t=395286)
    1.  `apt -y install dkms linux-headers-amd64 git kmod libssl-dev checkinstall`
    2. `wget https://github.com/patjak/facetimehd/archive/refs/tags/0.5.18.tar.gz`
    3. `tar xf 0.5.18.tar.gz -C /usr/src/`
    4. `dkms add -m facetimehd -v 0.5.18`
    5. `dkms build -m facetimehd -v 0.5.18`
    6. `dkms install -m facetimehd -v 0.5.18`
    7. `sudo echo "facetimehd" >> /etc/modules`
    8. `git clone https://github.com/patjak/facetimehd-firmware.git`
        - `cd ./facetimehd-firmware/`
        - `make`
        - `make install`
        
5. Neovim Installation and Setup
   1. Debian has Neovim: sudo apt-get install neovim
   2. [Custom Installation Script](neovim/install_neovim.sh)
   3. Neovim can be build using these steps: [Neovim/BUILD.md](https://github.com/neovim/neovim/blob/master/BUILD.md)
   4. Setting up Neovim
        1. [typecraft](https://www.youtube.com/@typecraft_dev)
        2. [lazy.nvim](https://github.com/folke/lazy.nvim)

6. [Rofi](https://gist.github.com/panicwithme/60d371ed85378154bf990fd1092a72c1) and 
    1. Install rofi (sudo apt install rofi
    2. Add the following line to the i3 config file. (~/.config/i3/config)
       `bindsym $mod+x exec "rofi -show drun" 
       - Reload i3 Config with "$Mod+Shift+r"
    3. Rofi can be configured by editing ~.config/rofi/config.rasi file.

7. [Picom Compositor](https://github.com/yshui/picom)
    1. [Youtube Video on installation](https://www.youtube.com/watch?v=t6Klg7CvUxA)
  
8. Enabling [Tap to Click Feature on Scrollpad](https://cravencode.com/post/essentials/enable-tap-to-click-in-i3wm/)

         
