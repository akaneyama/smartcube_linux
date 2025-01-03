#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root/sudo"
    echo "must run with root privileges or sudo"
    exit
fi

wget -q --spider https://wireguard.com

echo "Checking your internet..."
sleep 2
if [ $? -eq 0 ]; then
    echo "Online"
else
    echo "Offline"
    exit
fi

echo "Updating your repositori..."
sleep 2

sudo apt update 

echo "wireguard installation.."

if sudo apt install -y wireguard; then
    echo "Installation successful."
else
    echo "Installation failed. Exiting."
    exit 1
fi

echo "Validating current IPv4 forwarding status..."

# Cek nilai saat ini dari net.ipv4.ip_forward
current_value=$(sysctl -n net.ipv4.ip_forward)

if [ "$current_value" -eq 1 ]; then
    echo "IPv4 forwarding is already enabled. No changes required."
    exit 0
else
    echo "IPv4 forwarding is disabled or not set properly. Proceeding to update sysctl.conf..."
fi

# Lakukan validasi dan update file sysctl.conf
if grep -q '^#net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    # Baris ditemukan, lakukan perubahan dan apply
    echo "Updating your sysctl.conf..."
    sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf
elif grep -q '^net.ipv4.ip_forward=' /etc/sysctl.conf; then
    # Jika ada, ubah nilainya menjadi 1
    echo "Updating existing net.ipv4.ip_forward to 1..."
    sudo sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
    # Jika tidak ada, tambahkan baris baru
    echo "Adding net.ipv4.ip_forward=1 to sysctl.conf..."
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null
fi

# Terapkan konfigurasi
echo "Applying sysctl settings..."
sudo sysctl -p
echo "IPv4 forwarding enabled successfully!"
