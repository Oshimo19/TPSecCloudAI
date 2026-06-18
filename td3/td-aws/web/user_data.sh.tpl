#!/bin/bash
set -euxo pipefail

# Installation dependances
sleep 20
dnf update -y
dnf install -y python3 python3-pip
python3 -m pip install --upgrade pip
python3 -m pip install flask gunicorn requests

mkdir -p /opt/td3-web
cat > /opt/td3-web/web.py.b64 <<'WEBB64'
${web_py_b64}
WEBB64
base64 -d /opt/td3-web/web.py.b64 > /opt/td3-web/web.py

cat > /etc/systemd/system/td3-web.service <<SERVICEEOF
[Unit]
Description=TD3 Flask web tier
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/td3-web
Environment="INTERNAL_ALB_DNS=${internal_alb_dns}"
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:80 web:app
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable td3-web
systemctl restart td3-web
