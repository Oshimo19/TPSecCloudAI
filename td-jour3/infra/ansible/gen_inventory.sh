#!/usr/bin/env bash
# Génère inventory.ini depuis les outputs Terraform
set -euo pipefail

TF_DIR="../terraform"
KEY_WEB="$HOME/.ssh/td-j3-key-web"
KEY_APP="$HOME/.ssh/td-j3-key-app"

cd "$TF_DIR"
WEB_IPS=$(terraform output -json web_public_ips | jq -r '.[]')
APP_IPS=$(terraform output -json app_private_ips | jq -r '.[]')
ALB_INT=$(terraform output -raw alb_internal_dns)
RDS_HOST=$(terraform output -raw rds_endpoint)
RDS_DB=$(terraform output -raw rds_database_name)
RDS_USER=$(terraform output -raw rds_username)
PEPPER=$(terraform output -raw pepper)
cd - >/dev/null

# Récup du mot de passe RDS via Secrets Manager
DB_PASS=$(aws secretsmanager get-secret-value \
  --secret-id td-ipssi-rds-v2/password \
  --query SecretString --output text | jq -r '.password')

# Première IP web sert de bastion pour le ProxyJump des app
WEB_BASTION=$(echo "$WEB_IPS" | head -n1)

{
echo "[web]"
i=1
for ip in $WEB_IPS; do
  echo "web${i} ansible_host=${ip} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_WEB}"
  i=$((i+1))
done

echo ""
echo "[app]"
i=1
for ip in $APP_IPS; do
  echo "app${i} ansible_host=${ip} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_APP} ansible_ssh_common_args='-o ProxyCommand=\"ssh -i ${KEY_WEB} -W %h:%p -q ec2-user@${WEB_BASTION}\"'"
  i=$((i+1))
done

echo ""
echo "[all:vars]"
echo "alb_internal_dns=${ALB_INT}"
echo "rds_host=${RDS_HOST}"
echo "rds_db=${RDS_DB}"
echo "rds_user=${RDS_USER}"
echo "rds_password=${DB_PASS}"
echo "pepper=${PEPPER}"
} > inventory.ini

echo "inventory.ini généré"
