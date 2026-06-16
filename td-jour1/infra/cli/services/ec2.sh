#!/bin/bash

# Fonction pour créer une Network ACL
create_nacl() {
    local NACL_NAME="$1"

    echo "Création de la NACL '$NACL_NAME' dans le VPC $VPC_ID" >&2
    response=$(aws ec2 create-network-acl \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=$NACL_NAME}]")

    # Extraire ID ACL dans JSON de réponse
    NACL_ID=$(echo "$response" | grep -o '"NetworkAclId": "[^"]*"' | cut -d'"' -f4)

    # Sauvegarder la réponse dans un fichier
    echo "$response" > nacl.json

    # Vérification
    if [[ -n "$NACL_ID" && "$NACL_ID" != "None" ]]; then
        echo "[+] NACL '$NACL_NAME' créée avec succès (ID: $NACL_ID)" >&2
    else
        echo "[-] Échec de création de la NACL" >&2
        return 1
    fi
}

# Fonction pour supprimer une Network ACL
delete_nacl() {
    local NACL_NAME="$1"

    echo "Recherche de la NACL '$NACL_NAME' dans le VPC $VPC_ID"

    # 1. Essayer de lire ID ACL dans nacl.json
    if [[ -f "nacl.json" ]]; then
        NACL_ID=$(grep -o '"NetworkAclId": "[^"]*"' nacl.json | cut -d'"' -f4)

        # 2. Si ID ACL est trouvé, supprimer
        if [[ -n "$NACL_ID" && "$NACL_ID" != "None" ]]; then
            echo "Suppression de la NACL avec ID: $NACL_ID"
            if aws ec2 delete-network-acl --network-acl-id "$NACL_ID"; then
                echo "[+] NACL '$NACL_NAME' (ID: $NACL_ID) supprimée"
                rm -f nacl.json
            else
                echo "[-] Échec de suppression de la NACL (ID: $NACL_ID)"
                return 1
            fi
        else
            echo "[-] Erreur : Aucune NACL valide trouvée dans nacl.json"
            return 1
        fi
    else
        echo "[-] Erreur : Le fichier nacl.json n'existe pas"
        return 1
    fi
}

# Fonction pour créer des règles entrantes
create_ingress_rule() {
    local network_acl_id="$1"
    local rule_number="$2"
    local protocol="${3:-6}"            # 6 = TCP par défaut
    local from_port="${4:-443}"         # Port source par défaut 443
    local to_port="${5:-443}"           # Port destination par défaut 443
    local rule_action="${6:-"deny"}"    # Action par défaut: deny

    aws ec2 create-network-acl-entry \
        --network-acl-id "$network_acl_id" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range From="$from_port",To="$to_port" \
        --cidr-block 0.0.0.0/0 \
        --rule-action "$rule_action" \
        --ingress
}

# Fonction pour créer des règles sortantes
create_egress_rule() {
    local network_acl_id="$1"
    local rule_number="$2"
    local protocol="${3:-6}"            # 6 = TCP par défaut
    local from_port="${4:-443}"         # Port source par défaut 443
    local to_port="${5:-443}"           # Port destination par défaut 443
    local rule_action="${6:-"deny"}"    # Action par défaut: deny

    aws ec2 create-network-acl-entry \
        --network-acl-id "$network_acl_id" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range From="$from_port",To="$to_port" \
        --cidr-block 0.0.0.0/0 \
        --rule-action "$rule_action" \
        --egress
}
