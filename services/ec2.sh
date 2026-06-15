#!/bin/bash

create_nacl() {
    aws ec2 create-network-acl \
        --vpc-id "vpc-0ebcdb39f7a526ef9" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=walid-nacl}]"
}

create_nacl
