#!/bin/bash
set -euxo pipefail

# Installation dependances
sleep 20
dnf update -y
dnf install -y python3 python3-pip
python3 -m pip install --upgrade pip
python3 -m pip install flask gunicorn psycopg2-binary

mkdir -p /opt/td3-app
cat > /opt/td3-app/app.py.b64 <<'APPB64'
${app_py_b64}
APPB64
base64 -d /opt/td3-app/app.py.b64 > /opt/td3-app/app.py

cat > /etc/systemd/system/td3-app.service <<SERVICEEOF
[Unit]
Description=TD3 Flask API app tier
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/td3-app
Environment="DB_HOST=${db_host}"
Environment="DB_NAME=${db_name}"
Environment="DB_USER=${db_user}"
Environment="DB_PASSWORD=${db_password}"
Environment="DB_PORT=5432"
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:80 app:app
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable td3-app
systemctl restart td3-app
