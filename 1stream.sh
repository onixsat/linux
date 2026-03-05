#!/bin/bash

# Exit the script if any command fails
set -e

echo "Starting Nginx configuration update..."

# Define URLs for the configuration files
URL_NGINX_CONF="https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/nginx.conf"
URL_DEFAULT="https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-enabled/default"
URL_BO_CONF="https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-available/bo.conf"
URL_LB_CONF="https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-available/lb.conf"

# 1. Download the new configuration files
echo "Downloading configuration files..."
wget -q $URL_NGINX_CONF -O nginx.conf
wget -q $URL_DEFAULT -O default
wget -q $URL_BO_CONF -O bo.conf
wget -q $URL_LB_CONF -O lb.conf

# 2. Create backups of the existing configuration files
echo "Creating backups of current configurations..."
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp2 || echo "Warning: /etc/nginx/nginx.conf not found."
sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bkp2 || echo "Warning: /etc/nginx/sites-enabled/default not found."
sudo cp /etc/nginx/sites-available/bo.conf /etc/nginx/sites-available/bo.conf.bkp2 || echo "Warning: /etc/nginx/sites-available/bo.conf not found."
sudo cp /etc/nginx/sites-available/lb.conf /etc/nginx/sites-available/lb.conf.bkp2 || echo "Warning: /etc/nginx/sites-available/lb.conf not found."

# 3. Apply the new configuration files
echo "Applying new configuration files..."
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo cp default /etc/nginx/sites-enabled/default
sudo cp bo.conf /etc/nginx/sites-available/bo.conf
sudo cp lb.conf /etc/nginx/sites-available/lb.conf

# 4. Test the Nginx configuration for syntax errors
echo "Testing Nginx configuration..."
sudo nginx -t

# 5. Restart the Nginx service to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Cleanup temporary downloaded files
rm nginx.conf default bo.conf lb.conf

echo "Update completed successfully!"
