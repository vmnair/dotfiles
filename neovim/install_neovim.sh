# Install Neovim
# Prerequisites
sudo apt-get install ninja-build gettext cmake unzip curl
echo "Moving to home folder"
cd ~ || exit
echo "Checking for Neovim Folder ..."
rm -rf Neovim
echo "Removing installed version of Neovim..."
apt-get remove neovim
# Download Neovim
git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=Release
git checkout stable
# Using this we can uninstall installed version of Neovim
cd build && cpack -G DEB && sudo dpkg -i nvim-linux64.deb

echo "Installation completed, logout & log back in"
