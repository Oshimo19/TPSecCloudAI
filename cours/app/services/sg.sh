#!/bin/bash

# Fonction pour creer un security group (SG)
create_sg()  {
    local group_name="$1"
    local description="$2"
    local vpc_id="$3"

    aws ec2 create-security-id --groupe-name $group_name  \
        --description $description --vpc-id $vpc_id
}
