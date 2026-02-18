#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Web Tier is UP</h1>" | tee /usr/share/nginx/html/index.html