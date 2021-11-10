#!/bin/bash 



sed -i '/cdrom/d' '/etc/apt/sources.list'
rm /etc/apt/sources.list
cp sources.list /etc/apt/
apt update && apt upgrade -y
apt install git sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common bmon -y
git clone https://github.com/oblique/create_ap
git clone https://github.com/Mange/rtl8192eu-linux-driver
wget http://www.mobile-stream.com/beta/debian/10/easytether_0.8.9_amd64.deb
cd rtl8192eu-linux-driver
dkms add .   
dkms install rtl8192eu/1.0
echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
echo -e "8192eu\n\nloop" | sudo tee /etc/modules
echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
sudo update-grub; sudo update-initramfs -u
mv /etc/network/interfaces /etc/network/interfaces.backup
cp interfaces /etc/network/
ifup wlx7cc2c611779b 
gdebi easytether_0.8.9_amd64.deb
easytether-usb
dhcpcd tun-easytether
systemctl restart systemd-networkd
sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
sudo apt install apt-transport-https
wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
sudo apt update
sudo apt install jellyfin
docker run -it -p 57:57/udp -p 57:57/tcp -p 8080:80 --name pihole pihole/pihole
