#!/bin/bash

VPC_ID="vpc-0ebcdb39f7a526ef9"
NACL_FILE="nacl.json"

create_ingress_rule() {
    local network_acl_id="$1"
    local rule_number="$2"
    local protocol=${3:-6}
    local from=${4:-443}
    local to=${5:-443}
    local rule_action=${6:-"deny"}

    aws ec2 create-network-acl-entry \
        --network-acl-id "$network_acl_id" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range From="$from",To="$to" \
        --cidr-block "0.0.0.0/0" \
        --rule-action "$rule_action" \
        --ingress
}

create_nacl() {
    local nacl_name="$1"

    aws ec2 create-network-acl \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=$nacl_name}]" \
        --query '{NetworkAclId: NetworkAcl.NetworkAclId}' \
        --output json \
        > "$NACL_FILE"
}

get_nacl_id_from_file() {
    grep -o '"NetworkAclId": "[^"]*' "$NACL_FILE" | cut -d'"' -f4
}

delete_nacl() {
    local nacl_id="$1"

    aws ec2 delete-network-acl \
        --network-acl-id "$nacl_id"
}

# Programme principal

NACL_NAME=${1:-"walid-nacl"}
RULE_NUMBER=${2:-100}

create_nacl "$NACL_NAME"

NETWORK_ACL_ID=$(get_nacl_id_from_file)

echo "Network ACL créée : $NETWORK_ACL_ID"

create_ingress_rule "$NETWORK_ACL_ID" "$RULE_NUMBER"