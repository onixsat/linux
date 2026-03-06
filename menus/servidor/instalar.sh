#!/bin/bash

# Update system packages
log_info "Updating package lists and upgrading system..."
add "Atualizar" "sudo apt update -y" "1"
add "Atualizar" "sudo apt upgrade -y" "1"

step "Ficheiro data.txt"
    try echo 'This is a test' > data.txt
    #try mv file.txt data.txt
    try echo 'yet another line' >> data.txt
next

#sudo apt --yes -o Dpkg::Options::="--force-confnew" upgrade

# Add PHP PPA BEFORE installing PHP packages
#log_info "Adding Ondrej PHP PPA..."
#sudo add-apt-repository ppa:ondrej/php -y
#sudo apt update -y
read -n 1 -s -p "Press any key to continue 2"
clear
titulo "Instalar pacotes do sistema..."
log_info "Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ufw \
    net-tools \
    nginx \
    php8.1-fpm \
    php8.1-mcrypt \
    openssh-server \
    dos2unix \
    certbot \
    python3-certbot-nginx \
    git \
    iptables-persistent \
    fail2ban \
    curl

echo "Pacotes instalados!"
esperar "sleep 5" "${WHITE}completo! "

read -s -n 1 -p "Press any key to continuar 3!"
clear

# Configure UFW (Uncomplicated Firewall)
log_info "Configuring UFW..."
ufw allow 22
ufw allow 80/tcp 
ufw allow 443/tcp 
ufw allow 21/tcp 
ufw allow 8080/tcp 
ufw allow 8443/tcp 
ufw allow 9000/tcp 
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

read -n 1 -s -p "Press any key to continue 4"
clear

log_info "Configuring iptables..."
sudo iptables -I INPUT 1 -p tcp --dport 21 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9000 -j ACCEPT

read -n 1 -s -p "Press any key to continue 5"
clear
# Install Nginx UI
echo "Installing Nginx U..." 
log_info "Installing Nginx UI..."
read -s -n 1 -p "Press any key to continue!"
if ! command -v nginx-ui &> /dev/null; then
    bash -c "$(curl -fsSL https://cloud.nginxui.com/install.sh)" @ install
else
    log_warn "Nginx UI already installed, skipping..."
fi

read -n 1 -s -p "Press any key to continue 61"
clear

echo "Script complete! Rebooting..." 
read -s -n 1 -p "Press any key to reboot!"
systemctl restart nginx
