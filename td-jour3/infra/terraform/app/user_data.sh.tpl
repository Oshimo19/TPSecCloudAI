#!/bin/bash
# cloud-init user_data pour le tier App (Amazon Linux 2023)
# Template Terraform : bash exécuté à la première initialisation de l'EC2

set -euo pipefail

# ─── Mise à jour et dépendances système ───
dnf update -y
dnf install -y python3 python3-pip gcc postgresql15 postgresql15-devel

mkdir -p /opt/app

# ─── Écriture des fichiers source (base64 pour éviter les soucis d'échappement) ───
# app.py
base64 -d <<'B64EOF' > /opt/app/app.py
${app_py_b64}
B64EOF

# requirements.txt
base64 -d <<'B64EOF' > /opt/app/requirements.txt
${requirements_b64}
B64EOF

# ─── Variables d'environnement (fichier .env) ───
cat <<'EOF' > /opt/app/.env
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
PEPPER=${pepper}
EOF

# ─── Installation des paquets Python ───
pip3 install -r /opt/app/requirements.txt

# ─── Service systemd pour lancer l'API au boot ───
cat <<'EOF' > /etc/systemd/system/app.service
[Unit]
Description=TD IPSSI API Flask
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ─── Démarrage ───
systemctl daemon-reload
systemctl enable app.service
systemctl start app.service
