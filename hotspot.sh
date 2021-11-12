#!/bin/bash


echo 3559 | sudo -S easytether-usb
echo 3559 | sudo -S dhcpcd tun-easytether
echo 3559 | sudo -S systemctl restart systemd-networkd
echo 3559 | sudo -S create_ap wlan0 tun-easytether Home-Server Piragenth@3559 &


