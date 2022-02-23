#!/bin/bash -i
sudo apt update
sudo apt upgrade -y
sudo apt install bmon curl wget gdebi neofetch cmatrix -y
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb 
echo 'y' | gdebi cloudflared-linux-amd64.deb
cloudflared tunnel login
cp services/* /etc/systemd/system/
cp -r startup-script /home/achuthan/
sudo systemctl enable $(ls /etc/systemd/system/public*)
