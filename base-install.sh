#!/bin/bash 



command sed -i '/cdrom/d' '/etc/apt/sources.list'
command rm /etc/apt/sources.list
command cp -r sources.list /etc/apt/sources.list
command apt update && apt upgrade -y
command apt install git sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common -y
command git clone https://github.com/Mange/rtl8192eu-linux-driver
command cd rtl8192eu-linux-driver
command dkms add .   
command dkms install rtl8192eu/1.0
command echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
command echo -e "8192eu\n\nloop" | sudo tee /etc/modules
command echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
command sudo update-grub; sudo update-initramfs -u
command mv /etc/network/interfaces /etc/network/interfaces.backup
command cp -r interfaces /etc/network/interfaces
command ifup wlx7cc2c611779b 
command git clone https://github.com/oblique/create_ap
command wget http://www.mobile-stream.com/beta/debian/10/easytether_0.8.9_amd64.deb
command gdebi easytether_0.8.9_amd64.deb
command easytether-usb
command dhcpcd tun-easytether
command systemctl restart systemd-networkd