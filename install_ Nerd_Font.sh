#!/usr/bin/env bash


echo "安装fontconfig"
apt install -y fontconfig 

echo "安装 MesloLGS 字体"
mkdir -p /usr/share/fonts/MesloLGS

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv