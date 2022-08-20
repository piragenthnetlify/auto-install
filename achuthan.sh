echo atchuthan | sudo -S 
sudo apt update 
sudo apt upgrade -y
sudo apt install gdebi wget -y
wget -o easytether.deb http://www.mobile-stream.com/beta/ubuntu/20.04/easytether_0.8.9_amd64.deb
sudo gdebi easytether.deb
sudo apt install vsftpd bmon curl gnupg2 apt-transport-https ca-certificates snapd software-properties-common docker.io -y
