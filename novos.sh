# bash -c "$(curl -fsSL https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/novos.sh)" @ novos
#!/bin/bash

sudo su
sudo apt update -y
wget https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/nginx.conf
wget https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-enabled/default
wget https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-available/bo.conf
wget https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados/etc/nginx/sites-available/lb.conf
# BACKUP ORIGINAIS
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp2
sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bkp2
sudo cp /etc/nginx/sites-available/bo.conf /etc/nginx/sites-available/bo.conf.bkp2
sudo cp /etc/nginx/sites-available/lb.conf /etc/nginx/sites-available/lb.conf.bkp2
# NOVOS
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo cp default /etc/nginx/sites-enabled/default
sudo cp bo.conf /etc/nginx/sites-available/bo.conf
sudo cp lb.conf /etc/nginx/sites-available/lb.conf
nginx-t
systemctl restart nginx
