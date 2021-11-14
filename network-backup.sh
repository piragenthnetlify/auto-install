#!/bin/bash
cd
yes "3559" | sudo -S cp /etc/apt/sources.list .
dpkg --get-selections > installed-software
yes "3559" | sudo -S smbmount //192.168.1.2/BackUp/Timeshift-Ryzen-Arch name /media/piragenth -o username=root,password=3559,uid=1000,mask=000
rsync -arquz /media/piragenth/
yes "3559" | sudo -S smbumount /media/piragenth
exit
