echo atchuthan | sudo -S 
sudo apt update 
#sudo apt upgrade -y
sudo apt install gdebi wget -y
wget -o easytether.deb http://www.mobile-stream.com/beta/ubuntu/20.04/easytether_0.8.9_amd64.deb
sudo gdebi easytether.deb
sudo easytether-usb 

echo "Disconnect the ethernet"
sudo apt install vsftpd bmon curl gnupg2 apt-transport-https ca-certificates snapd software-properties-common docker.io smbd -y

sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-networkd
sudo systemctl status systemd-networkd
sudo docker pull linuxserver/jellyfin
sudo docker pull linuxserver/plex
sudo docker pull linuxserver/emby
