echo atchuthan | sudo -S 
sudo apt update 
sudo apt upgrade -y
sudo apt install vsftpd bmon curl gnupg2 apt-transport-https ca-certificates snapd software-properties-common -y
sudo systemctl start vsftpd 
sudo systemctl enable vsftpd
docker pull jwilder/nginx-proxy
docker pull nginx
docker pull jrcs/letsencrypt-nginx-proxy-companion
docker pull mariadb
docker pull nextcloud
docker pull willfarrell/autoheal
docker pull dorowu/ubuntu-desktop-lxde-vnc:bionic
snap install nextcloud
sudo snap set nextcloud ports.http=81
mkdir docker-ubuntu
wget https://agiledevart.github.io/Dockerfile.lubuntu -P $(pwd)/docker-ubuntu
wget https://agiledevart.github.io/Dockerfile.ubuntu
docker build -t docker-ubuntu .
docker build -t docker-lubuntu $(pwd)/docker-ubuntu/
sudo apt update 
sudo apt upgrade -y