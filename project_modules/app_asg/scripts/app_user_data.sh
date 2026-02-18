#!/bin/bash
dnf update -y
dnf install -y python3

mkdir -p /opt/app
echo "Hello from App Tier on port 8080" | tee /opt/app/index.html

cat <<SERVICE | tee /etc/systemd/system/app.service
[Unit]
Description=Simple App Server
After=network.target

[Service]
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable app
systemctl start app