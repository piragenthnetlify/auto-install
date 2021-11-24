echo "piragenth's auto install"

echo "YOU NEED TO ROOT TO RUN THIS SCRIPT"

echo "what distro are you using Debian or Ubuntu :"
read distro

if [[ $distro == "debian" ]]; then
    sed -i '/cdrom/d' '/etc/apt/sources.list'
    echo "Do you want to change sources.list (y/n)"
    read change_sources
fi

echo "Do you want to create hotspot using create_ap (y/n):"
read hotspot

echo "Do you want to install TL-WN823N drivers (y/n):"
read wifi_usb

echo "Do you want change /etc/network/interfaces (y/n):"
read interfaces

echo "Do you want to install OpenMediaVault (y/n):"
read omv

echo "Do you want to install jellyfin (y/n):"
read jellyfin

echo "Do you want to install Pihole in docker (y/n)"
read pihole_yn

if [[ $pihole_yn == "y" ]]; then
    echo "what pihole do you want to install networkchunk/nc or defaultpihole/pihole"
    read pihole
fi

echo "Do you want to pull ubuntu in docker (y/n)"
read pull_ubuntu

echo "Do you want to install syncthing in docker"
read syncthing

echo "Do you want to install jdownloader in docker"
read jdownloader

echo "Do you want to install PlexMediaServer"
read plex

echo "Updating and upgrading system..."

systemctl stop systemd-resolved
systemctl disable systemd-resolved
mv /etc/resolv.conf /etc/resolv.autoinstall.backup
cp resolv.conf /etc/

apt update && apt upgrade -y

echo "installing basic pakages to install easytether"
apt install git gdebi dhcpcd5 wget
wget http://www.mobile-stream.com/beta/debian/10/easytether_0.8.9_amd64.deb
gdebi easytether_0.8.9_amd64.deb
easytether-usb
dhcpcd tun-easytether
systemctl restart systemd-networkd


if [[ $distro == "ubuntu" ]]; then
    echo $distro


    echo "Updating and Upgrading system ..."
    apt update && apt upgrade -y
    echo "Installing essential packages..."
    apt install snapd hostapd git sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common bmon ifupdown python3-pip-y
    pip install docker-compose

    if [[ $hotspot == "y" ]]; then
        echo "cloning into https://github.com/oblique/create_ap"
        git clone https://github.com/oblique/create_ap
	cd create_ap
	make install
	cd ..
 	./hotspot.sh
    fi

    if [[ $wifi_usb == "y" ]]; then
        echo "cloning into https://github.com/Mange/rtl8192eu-linux-driver"
        git clone https://github.com/Mange/rtl8192eu-linux-driver
        echo "Installing wifi Drivers"
        cd rtl8192eu-linux-driver
        dkms add .   
        dkms install rtl8192eu/1.0
        echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
        echo -e "8192eu\n\nloop" | sudo tee /etc/modules
        echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
        sudo update-grub; sudo update-initramfs -u
    fi

    if [[ $interfaces == "y" ]]; then
        echo "changing interfaces configuration"
        mv /etc/network/interfaces /etc/network/interfaces.backup
        cp interfaces /etc/network/
        echo "updating wireless interface "
        ifup wlx7cc2c611779b 
        ifup wlan0
    fi

    if [[ $omv == "y" ]]; then
        echo "Installing OMV"
	#sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
	sudo curl -sSL https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash


    fi

    if [[ $jellyfin == "y" ]]; then
        echo "Installing jellyfin"
        wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
        echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
        sudo apt update
        sudo apt install jellyfin
    fi
    if [[ $pull_ubuntu == "y" ]]; then
        echo "PUll Ubuntu from docker"
        docker pull ubuntu
    fi

    if [[ $pihole_yn == "y" ]]; then
        if [[ $pihole == "pihole" ]]; then
            echo "installing pihole"
            docker run -it -p 53:53/udp -p 53:53/tcp -p 47:47/udp -p 47:47/tcp -p 67:67/tcp -p 67:67/udp -p 443:443 -p 8080:80 --name pihole pihole/pihole
        fi

        if [[ $pihole == "nc" ]]; then
            echo "Installing networkchunk pihole"
            wget -c https://raw.githubusercontent.com/theNetworkChuck/NetworkChuck/master/pihole.sh -O networkchunk-pihole.sh
            chmod u+x networkchunk-pihole.sh
            ./networkchunk-pihole.sh
        fi
    fi

<<<<<<< HEAD
    if [[ $syncthing == "y"]]; then
        echo "installing syncthing in Docker..."
        cd syncthing
        docker-compose up
    fi

    if [[ $jdownloader == "y" ]]; then
        echo "installing jdownloader in Docker..."
        cd jdownloader
        docker-compose up
    fi


    if [[ $pull_ubuntu == "y" ]]; then
        echo "PUll Ubuntu from docker"
        docker pull ubuntu
    fi

    if [[ $plex == "y" ]]; then
        echo "installing plexmediaserver"
        snap install plexmediaserver
    fi

=======

>>>>>>> 6571851c3d1b9722071fcccc079eb63f3b38238a
fi




if [[ $distro == "debian" ]]; then
    echo $distro
 
    if [[ $change_sources == "y" ]]; then
        rm /etc/apt/sources.list
        cp sources.list /etc/apt/
    fi
    
    echo $distro
    echo "Updating and Upgrading system in Debian..."
    apt update && apt upgrade -y
    echo "Installing essential packages..."
    apt install git snapd sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common bmon python3-pip ifupdown -y
    pip install docker-compose
    if [[ $hotspot == "y" ]]; then
        echo "cloning into https://github.com/oblique/create_ap"
        git clone https://github.com/oblique/create_ap
    fi

    if [[ $wifi_usb == "y" ]]; then
        echo "cloning into https://github.com/Mange/rtl8192eu-linux-driver"
        git clone https://github.com/Mange/rtl8192eu-linux-driver
        echo "Installing wifi Drivers"
        cd rtl8192eu-linux-driver
        dkms add .   
        dkms install rtl8192eu/1.0
        echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
        echo -e "8192eu\n\nloop" | sudo tee /etc/modules
        echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
        sudo update-grub; sudo update-initramfs -u
    fi

    if [[ $interfaces == "y" ]]; then
        echo "changing interfaces configuration"
        mv /etc/network/interfaces /etc/network/interfaces.backup
        cp interfaces /etc/network/
        echo "updating wireless interface "
        ifup wlx7cc2c611779b 
        ifup wlan0
    fi

    if [[ $omv == "y" ]]; then
        echo "Installing OMV"
        sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
    fi

    if [[ $jellyfin == "y" ]]; then
        echo "Installing jellyfin"
        wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
        echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
        sudo apt update
        sudo apt install jellyfin
    fi
    if [[ $pull_ubuntu == "y" ]]; then
        echo "PUll Ubuntu from docker"
        docker pull ubuntu
    fi

    if [[ $pihole_yn == "y" ]]; then
        if [[ $pihole == "pihole" ]]; then
            echo "installing pihole"
            systemctl stop systemd-resolved
            systemctl disable systemd-resolved
            mv /etc/resolv.conf /etc/resolv.autoinstall.backup
            cp resolv.conf /etc/
            docker run -it -p 53:53/udp -p 53:53/tcp -p 47:47/udp -p 47:47/tcp -p 67:67/tcp -p 67:67/udp -p 443:443 -p 8080:80 --name pihole pihole/pihole
        fi

        if [[ $pihole == "nc" ]]; then
            echo "Installing networkchunk pihole"
            wget -c https://raw.githubusercontent.com/theNetworkChuck/NetworkChuck/master/pihole.sh -O networkchunk-pihole.sh
            chmod u+x networkchunk-pihole.sh
            ./networkchunk-pihole.sh
        fi
    fi
    if [[ $syncthing == "y"]]; then
        echo "installing syncthing in Docker..."
        cd syncthing
        docker-compose up
    fi
    
    if [[ $jdownloader == "y" ]]; then
        echo "installing jdownloader in Docker..."
        cd jdownloader
        docker-compose up
    fi
    if [[ $plex == "y" ]]; then
        echo "installing plexmediaserver"
        snap install plexmediaserver
    fi

    
fi





