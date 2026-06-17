ANSIBLE_DIR := infra/ansible
TF_DIR := infra/terraform
INFO_COLOR := \033[36;1m
# Bonne pratique
NO_COLOR := \033[0m

.PHONY: help tr_init tr_lint tr_plan tr_apply tr_output known_hosts ping play build clean
.DEFAULT_GOAL := help

help: ## show this help
	@grep -E "^[a-zA-Z_-]+:.*## .*$$" $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "$(INFO_COLOR)%-20s$(NO_COLOR) %s\n", $$1, $$2}' | sort

tr_init: ## init terraform
	@cd $(TF_DIR) && terraform init

tr_lint: ## format and validate terraform configs
	@cd $(TF_DIR) && terraform fmt && terraform validate

tr_plan: tr_lint ## plan terraform
	@cd $(TF_DIR) && terraform plan

tr_apply: tr_plan ## apply terraform
	@cd $(TF_DIR) && terraform apply

tr_output: ## outputs ip into ansible inventory
	@echo "[web]" > $(ANSIBLE_DIR)/inventory.ini
	@terraform -chdir=$(TF_DIR) output test_wxm_bastion_public_ip | tr -d '"' | xargs -I{} echo "{} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/td-j1-key-bastion" >> $(ANSIBLE_DIR)/inventory.ini

known_hosts: ## add web host key to known_hosts
	@ssh-keyscan -H $$(terraform -chdir=$(TF_DIR) output -raw test_wxm_bastion_public_ip) >> ~/.ssh/known_hosts 2>/dev/null || true

ping: known_hosts ## ping web host in inventory
	@ansible -i $(ANSIBLE_DIR)/inventory.ini web -m ping

play: ## runs the playbook
	@ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/ngnix.yml

clean: ## destroy terraform infrastructure
	@cd $(TF_DIR) && terraform destroy

build: tr_apply tr_output known_hosts ping play ## full deployment
