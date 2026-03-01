#!/bin/bash
set -eu #set -euo pipefail
TIMEZONE=Africa/Lagos
export LC_ALL=en_US.UTF-8
add-apt-repository --yes universe
timedatectl set-timezone ${TIMEZONE} 
apt --yes install locales-all

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}
cleanup() {
    local code=$?
    if [ $code -ne 0 ]; then
        log_error "Script failed with exit code $code at line $LINENO"
    fi
    echo $code
}
trap cleanup ERR
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting VPS setup for vps-3026dd85.vps.ovh.net..."

# Update system packages
log_info "Updating package lists and upgrading system..."
sudo apt update -y
sudo apt upgrade -y
sudo apt --yes -o Dpkg::Options::="--force-confnew" upgrade

# Add PHP PPA BEFORE installing PHP packages
log_info "Adding Ondrej PHP PPA..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

#titulo "Instalar pacotes do sistema..."
log_info "Installing required packages..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
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

#echo "${WHITE}Pacotes instalados!"
#esperar "sleep 5" "${WHITE}completo! "

read -s -n 1 -p "Press any key to continuar 2!"

# Configure UFW (Uncomplicated Firewall)
log_info "Configuring UFW..."
ufw allow 22
ufw allow 80/tcp 
ufw allow 443/tcp 
ufw allow 21/tcp 
ufw allow 8080/tcp 
ufw allow 8443/tcp 
ufw allow 9000/tcp 
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw --force enable

log_info "Configuring iptables..."
sudo iptables -I INPUT 1 -p tcp --dport 21 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9000 -j ACCEPT

read -s -n 1 -p "Press any key to continuar 3!"




#SPTH='/home/Foo/Documents/Programs/ShellScripts/Butler'

# Obtain SSL certificate
log_info "Obtaining SSL certificate for cloudflare..."
sudo mv ssl/ospro.pt.pem /etc/ssl/certs/
sudo mv ssl/ospro.pt.key /etc/ssl/private/
sudo chmod 644 /etc/ssl/certs/ospro.pt.pem
sudo chmod 640 /etc/ssl/private/ospro.pt.key

log_info "Obtaining SSL certificate for ospro.pt..."
sudo mv ssl/fullchain.cer /etc/nginx/ssl/ospro.pt_P256/fullchain.cer
sudo mv ssl/private.key /etc/nginx/ssl/ospro.pt_P256/private.key
sudo chmod 644 /etc/nginx/ssl/ospro.pt_P256/fullchain.cer
sudo chmod 640 /etc/nginx/ssl/ospro.pt_P256/private.key

read -s -n 1 -p "Press any key to continuar 4!"

# Install Nginx UI
log_info "Installing Nginx UI..."
if ! command -v nginx-ui &> /dev/null; then
    bash -c "$(curl -fsSL https://cloud.nginxui.com/install.sh)" @ install
else
    log_warn "Nginx UI already installed, skipping..."
fi

read -s -n 1 -p "Press any key to continuar 5!"

echo "Configurar nginx files..."
if [ -d "/var/www/stream" ] 
then
    echo "Directory /var/www/stream exists." 
    sudo rm -r /var/www/stream
    echo "Directory /var/www/stream removido." 
fi

echo "Copiar nginx files..."
sudo mv www/stream/ /var/www/
sudo cp sites-available/* /etc/nginx/sites-available/
sudo cp sites-enabled/* /etc/nginx/sites-enabled/

echo "Setting secure permissions..."
chown -R www-data:www-data /var/www/stream
chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/stream/*
chmod -R 777 /var/www/html/*

read -s -n 1 -p "Press any key to continuar 5!"

echo "Testing Nginx configuration..."
nginx -t

read -s -n 1 -p "Press any key to continuar 6!"

# Restart services
log_info "Restarting services..."
systemctl restart nginx
systemctl restart php8.1-fpm

# Start and enable Nginx UI
if systemctl list-unit-files | grep -q nginx-ui; then
    systemctl start nginx-ui
    systemctl enable nginx-ui
    log_info "Nginx UI started and enabled"
else
    log_warn "nginx-ui service not found"
fi
# Final status check
log_info "Performing final status checks..."
systemctl is-active --quiet nginx && log_info "Nginx is running" || log_error "Nginx failed to start"
systemctl is-active --quiet php8.1-fpm && log_info "PHP-FPM is running" || log_error "PHP-FPM failed to start"

if systemctl is-active --quiet nginx-ui 2>/dev/null; then
    log_info "Nginx UI is running"
else
    log_warn "Nginx UI status check failed"
fi

echo "Script complete! Rebooting..." 
read -s -n 1 -p "Press any key to reboot!"
reboot


