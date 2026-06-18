#!/bin/bash
set -euo pipefail

# ─── Dépendances ───
dnf update -y
dnf install -y python3 python3-pip

mkdir -p /opt/web

# ─── Fichiers sources (base64) ───
base64 -d <<'B64EOF' > /opt/web/web.py
${web_py_b64}
B64EOF

base64 -d <<'B64EOF' > /opt/web/requirements.txt
${requirements_b64}
B64EOF

# ─── Service systemd ───
cat <<EOF > /etc/systemd/system/web.service
[Unit]
Description=Tier Web Flask
After=network.target

[Service]
Type=simple
Environment="INTERNAL_ALB_DNS=${internal_alb_dns}"
WorkingDirectory=/opt/web
ExecStart=/usr/bin/python3 /opt/web/web.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

pip install -r /opt/web/requirements.txt

systemctl daemon-reload
systemctl enable web.service
systemctl start web.service
