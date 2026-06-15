#!/bin/bash

# Configuration
VPC_ID="$1"
NACL_NAME="$2"

# Fonction pour créer une Network ACL
create_nacl() {
    echo "Création de la NACL '$NACL_NAME' dans le VPC $VPC_ID"
    NACL_ID=$(aws ec2 create-network-acl \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=$NACL_NAME}]" \
        --query 'NetworkAcl.NetworkAclId' \
        --output text)

    if [[ -n "$NACL_ID" ]]; then
        echo "[+] NACL '$NACL_NAME' créée avec succès (ID: $NACL_ID)"
    else
        echo "[-] Échec de création de la NACL"
        return 1
    fi
}

# Fonction pour supprimer une Network ACL
delete_nacl() {
    echo "Recherche de la NACL '$NACL_NAME' dans le VPC $VPC_ID"
    NACL_ID=$(aws ec2 describe-network-acls \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$NACL_NAME" \
        --query 'NetworkAcls[0].NetworkAclId' \
        --output text)

    if [[ -n "$NACL_ID" ]]; then
        aws ec2 delete-network-acl --network-acl-id "$NACL_ID"
        echo "[+] NACL '$NACL_NAME' (ID: $NACL_ID) supprimée avec succès"
    else
        echo "[-] Erreur : Aucune NACL nommée '$NACL_NAME' trouvée dans le VPC $VPC_ID"
        return 1
    fi
}

# Vérification des arguments
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <VPC_ID> <NACL_NAME>"
    echo "Exemple: $0 vpc-0ebcdb39f7a526ef9 test-acl-23"
    exit 1
fi

# Appel de fonction (décommentez la ligne que vous voulez utiliser)
# create_nacl
delete_nacl
