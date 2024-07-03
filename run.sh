#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Continue with the rest of the script if running as root
sudo apt update
sudo apt install iproute2
sudo apt-get install -y iptables-persistent
echo "========================"
echo "select: "
echo "    1. Iran"
echo "    2. Kharej"
echo "    3. uninstall"
echo "========================"
# Prompt user for IP addresses
read -p "Select number : " choices
if [ "$choices" -eq 1 ]; then
  ipv4_address=$(curl -s https://api.ipify.org)
  echo "Iran IPv4 is : $ipv4_address"
  read -p "enter Kharej Ipv4 :" ip_remote
  read -p "enter network name :" network_name
ip tunnel add 6to4_IN mode sit remote $ip_remote
ip -6 addr add fd00:155::1/64 dev 6to4_IN
ip link set 6to4_IN mtu 1480
ip link set 6to4_IN up
sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.23.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.23.2
iptables -t nat -A POSTROUTING -j MASQUERADE
  #sudo nano /etc/rc.local && sudo chmod +x /etc/rc.local
  rctext='#!/bin/bash
ip tunnel add 6to4_IN mode sit remote '"$ip_remote"'
ip -6 addr add fd00:155::1/64 dev 6to4_IN
ip link set 6to4_IN mtu 1480
ip link set 6to4_IN up
sudo ip link add vxlan0 type vxlan id 3188 dstport 53 local fd00:155::1 remote fd00:155::2 dev '"$network_name"'
sudo ip link set vxlan0 mtu 1500
sudo ip link set vxlan0 up
sudo ip addr add 192.168.23.1/30 dev vxlan0
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo ip6tables -A INPUT -p udp --dport 53 -j ACCEPT
sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.23.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.23.2
iptables -t nat -A POSTROUTING -j MASQUERADE
exit 0
'
  sleep 0.5
  echo "$rctext" > /etc/rc.local
  echo "tunnel successfully."
  read -p "Do you want to get a ping? (recommended)[y/n]:" yes_no
  if [[ $yes_no =~ ^[Yy]$ ]] || [[ $yes_no =~ ^[Yy]es$ ]]; then
    ping6 fd00:155::1
  fi
elif [ "$choices" -eq 2 ]; then
  #sudo nano /etc/rc.local && sudo chmod +x /etc/rc.local
  ipv4_address=$(curl -s https://api.ipify.org)
  echo "Kharej IPv4 is : $ipv4_address"
  read -p "enter Iran Ip : " ip_remote
  read -p "enter network name :" network_name
  rctext='#!/bin/bash
ip tunnel add 6to4_OUT mode sit remote '"$ip_remote"'
ip -6 addr add fd00:155::2/64 dev 6to4_OUT
ip link set 6to4_OUT mtu 1480
ip link set 6to4_OUT up
sudo ip link add vxlan0 type vxlan id 3188 dstport 53 local fd00:155::2 remote fd00:155::1 dev '"$network_name"'
sudo ip link set vxlan0 mtu 1500
sudo ip link set vxlan0 up
sudo ip addr add 192.168.23.2/30 dev vxlan0
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo ip6tables -A INPUT -p udp --dport 53 -j ACCEPT
exit 0
'
  sleep 0.5
  echo "$rctext" > /etc/rc.local
  echo "tunnel successfully."
  read -p "Do you want to get a ping? (recommended)[y/n]:" yes_no
  if [[ $yes_no =~ ^[Yy]$ ]] || [[ $yes_no =~ ^[Yy]es$ ]]; then
    ping6 fd00:155::2
  fi
elif [ "$choices" -eq 3 ]; then
  echo > /etc/rc.local
  sudo mv /root/rc.local.old /etc/rc.local
  ip link show | awk '/6to4_IN/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/6to4_IN/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  ip link show | awk '/6to4_IN/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/6to4_IN/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  ip link show | awk '/6to4_OUT/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/6to4_OUT/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  ip link show | awk '/6to4_OUT/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/6to4_OUT/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  echo "uninstalled successfully"
  read -p "do you want to reboot?(recommended)[y/n] :" yes_no
  if [[ $yes_no =~ ^[Yy]$ ]] || [[ $yes_no =~ ^[Yy]es$ ]]; then
    reboot
  fi
elif [ "$choices" -eq 4 ]; then
  sudo apt install -y sudo wget
  wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh && chmod +x linux-optimizer.sh && bash linux-optimizer.sh 
else
  echo "wrong input"
  exit 1
fi
if [[ "$choices" -eq 1 || "$choices" -eq 2 ]]; then
  chmod +x /etc/rc.local
  sleep 0.5
  /etc/rc.local
  echo    # move to a new line

  if [ "$choices" -eq 2 ]; then
  echo "Local IPv6 Kharej: 2001:470:1f10:e1f::2"
  echo "Local Ipv6 Iran: 2001:470:1f10:e1f::1"
  fi
fi
