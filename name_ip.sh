#!/bin/bash

#Enter Fist IP address that you want users to use for static IP
frange="10.12.2.40"

# Enter the Last IP address that you want users to use for static IP
lrange="10.12.2.150"

# install fping
sudo apt-get install fping

#Get current machine info
interface=$(ifconfig -s | grep en | head -n1 | cut -d " " -f1)
currentip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f10)
currentmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep -o \\/.*)
currentdg=$(ip route | grep "default via" | sed  's/default via //g' | sed  's/dev.*//g')
currentdns=$(systemd-resolve --status | grep "DNS Servers" | sed 's/^.*DNS Servers: //g')

echo -e "\e[96m"




# get new hostname from user
echo "Type in Hostname and hit enter"

read hostname
echo
echo "List of Open IP Addresses"
sleep 3
echo -e "\e[39m"

openipaddress=$(fping -u -q -r 0 -g -u $frange $lrange | tee /dev/tty | head -n 1 )


echo -e "\e[96m"
echo "The current IP address is $currentip"
echo "The first Open IP address is $openipaddress"

echo "Enter an Ip address you want to use"
read ipaddress
echo
echo


echo "The current Subnet Mask, Default Gateway, and DNS Server are as follows:"
echo
echo "Subnet Mask: $currentmask"
echo "Default Gateway: $currentdg"
echo "DNS Server: $currentdns"
echo
echo "Do you want to keep the current SM,DG, and DNS? [Y/n]"

read an
	if [ "$an" = "Y" ] || [ "$an" = "y" ]; then
	 

	mask=$currentmask
	dg=$currentdg
	dns=$currentdns

	elif [ "$an" = "N" ] || [ "$an" = "n" ]; then
	 
	
	echo "Enter Subnet mask in slash format e.g. /24"
	echo "You must include the '/' character"
	read mask
	echo
	echo "Enter Default Gateway"
	read dg
	echo
	echo "Enter DNS Server"
	read dns

	else
	 echo "Invalid selection. Run the script again"
	 exit
	fi







echo "The Hostname will be $hostname"
echo "The IP address will be $ipaddress"
sudo hostnamectl set-hostname $hostname
echo -e "\e[39m"


# Disable cloud config of network
echo "network: {config: disabled}" | sudo tee  /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# Set Static IP address
 echo "network:
     version: 2
     renderer: networkd
     ethernets:
       $interface:
        dhcp4: no
        addresses: [$ipaddress$mask]
        gateway4: $dg
        nameservers:
          addresses: [$dns]" | sudo tee /etc/netplan/50-cloud-init.yaml


#Inform User
echo
echo -e "\e[96m"
echo "The prompt will change to the new hostname on your next ssh session"
echo
echo "The IP address will now be set to $ipaddress."
echo
echo "If you are using ssh, you will lose connectivity and you will need to ssh to the new address."
echo "If you are on the console, you will need to logout and log back in to see hostname changes"
echo
echo

read -n 1 -r -s -p $'Press enter to continue...\n'

echo -e "\e[39m"


# Change IP address without reboot

sudo ifconfig $interface $ipaddress netmask $mask ; sudo ip route add default via $dg dev $interface

