#!/bin/bash



create_sg(){
    local group_name="$1"
    local description="$2"
    local vpc_id="$3

    aws ec2 create-security-group \
        --group-name "$group_name" \
        --description "$description" \
        --vpc-id "$VPC_ID"
}