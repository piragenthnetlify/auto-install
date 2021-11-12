echo "piragenth's auto install"

echo "YOU NEED TO ROOT TO RUN THIS SCRIPT"

echo "what distro are you using Debian or Ubuntu :"
read distro

if [[ $distro == "debian" ]]; then
    deb  sed -i '/cdrom/d' '/etc/apt/sources.list'
    echo "Do you want to change sources.list (y/n)"
    read change_sources

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

echo "Do you want to pull ubuntu in docker (y/n)"
read pull_ubuntu

echo "Updating and upgrading system..."

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
    echo "Updating and Upgrading system in Ubuntu..."
    apt update && apt upgrade -y
    echo "Installing essential packages..."
    apt install git sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common bmon -y

    if [[ $hotspot == "y" ]]; then
        echo "cloning into https://github.com/oblique/create_ap"
        git clone https://github.com/oblique/create_ap
    fi

    if [[ $wifi_usb == "y" ]]; then
        echo "cloning into https://github.com/Mange/rtl8192eu-linux-driver"
        git clone git clone https://github.com/Mange/rtl8192eu-linux-driver
        echo "Installing wifi Drivers"
        cd rtl8192eu-linux-driver
        dkms add .   
        dkms install rtl8192eu/1.0
        echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
        echo -e "8192eu\n\nloop" | sudo tee /etc/modules
        echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
        sudo update-grub; sudo update-initramfs -u
        cd ..
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

    if [[ $pull_ubuntu == "y" ]]; then
        echo "PUll Ubuntu from docker"
        docker pull ubuntu
    fi
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
    apt install git sudo curl wget docker docker.io nano network-manager dhcpcd5 wireless-tools firmware-realtek linux-headers-generic build-essential dkms gdebi software-properties-common bmon -y

    if [[ $hotspot == "y" ]]; then
        echo "cloning into https://github.com/oblique/create_ap"
        git clone https://github.com/oblique/create_ap
    fi

    if [[ $wifi_usb == "y" ]]; then
        echo "cloning into https://github.com/Mange/rtl8192eu-linux-driver"
        git clone git clone https://github.com/Mange/rtl8192eu-linux-driver
        echo "Installing wifi Drivers"
        cd rtl8192eu-linux-driver
        dkms add .   
        dkms install rtl8192eu/1.0
        echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
        echo -e "8192eu\n\nloop" | sudo tee /etc/modules
        echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
        sudo update-grub; sudo update-initramfs -u
        cd ..
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

    if [[ $pihole_yn == "y" ]]; then
        if [[ $pihole == "pihole"]]; then
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

    if [[ $pull_ubuntu == "y" ]]; then
        echo "PUll Ubuntu from docker"
        docker pull ubuntu
    fi
    
fi






