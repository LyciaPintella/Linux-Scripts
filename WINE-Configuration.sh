# Reinstall WINE:
su -
usermod -aG sudo jessica

# Log out and back in, then:
rm -rf ~/.wine
rm -rf ~/mywineprefix

# Install Dependencies:
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install --install-recommends wine wine32 wine64

# Create a clean prefix
wineboot --init

# Lock architecture:
export WINEARCH=win64
export WINEPREFIX=~/.wine
winecfg

# Make Environment Variables Permanent:
nano ~/.bashrc

# Add:
export WINEPREFIX="$HOME/.wine"
export WINEARCH=win64

# Save, then run:
source ~/.bashrc

# Stability Addon:
sudo apt install winetricks
winetricks corefonts vcrun2019

wine notepad
