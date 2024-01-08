# dotfiles
## Checklist For Installation:
- [ ] Debian Installation
    - [ ] Screen Resolution and Layout
- [x] Wifi Card Setup 
- [x] Neovim Installation & Setup
- [ ] i3 Windows Manager Installation & Setup

1. Debian installation.
    - [Official Debian Site for Installation of MacBook Pro](https://wiki.debian.org/MacBookPro)
2. WiFi
    1. MacBook Pro:

        a. Use `lspci` on terminal to list the PCI devices

        b. Look for Network Controller: In my case (2015 MBP, A1398) the controller is  Broadcom Inc. and subsidiaries BCM4360 802.11ac Dual Band Wireless Network Adapter (rev 03). We need to install the firmware for this to work.

        c. The interface name is `wlp3s0`

       d. See Details of the driver installation: [WiFi Driver Installation](https://unix.stackexchange.com/questions/175810/how-to-install-broadcom-bcm4360-on-debian-on-macbook-pro).
       
       e. wl driver needed for `bcm4360` [wl](https://wiki.debian.org/wl)

3. iSight Camera Not working:
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
4. Neovim Installation and Setup
   1. Debian has Neovim: sudo apt-get install neovim
   2. [Custom Installation Script](install_neovim.sh)
   3. Neovim can be build using these steps: [Neovim/BUILD.md](https://github.com/neovim/neovim/blob/master/BUILD.md)
   4. Setting up Neovim
        1. [typecraft](https://www.youtube.com/@typecraft_dev)
