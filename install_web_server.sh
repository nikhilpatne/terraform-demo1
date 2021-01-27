#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo bash -c 'echo My very first web server using terraform...!!! > /var/www/html/index.html'
