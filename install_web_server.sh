#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo apt install git -y
git clone https://github.com/nikhilpatne/cards.git
sudo cat cards/index.html > /var/www/html/index.html
