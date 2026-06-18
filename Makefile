TF_DIR := infra/terraform
ANSIBLE_DIR := infra/ansible
INFO_COLOR := \033[36;1m
NO_COLOR := \033[0m

.PHONY: help tr_init tr_lint tr_plan tr_apply tr_output play build
.DEFAULT_GOAL := help

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	awk -F': ##' '{printf "$(INFO_COLOR)%-20s$(NO_COLOR) %s\n", $$1, $$2}'

tr_init: ## initialize terraform
	@cd $(TF_DIR) && terraform init

tr_lint: ## format and validate terraform configs
	@cd $(TF_DIR) && terraform fmt && terraform validate

tr_plan: tr_lint
	@cd $(TF_DIR) && terraform plan

tr_apply: tr_plan
	@cd $(TF_DIR) && terraform apply

tr_output:
	@echo "[web]" > $(ANSIBLE_DIR)/inventory.ini
	@echo "$$(cd $(TF_DIR) && terraform output -raw test_wxm_bastion_public_ip) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/rayane-key" >> $(ANSIBLE_DIR)/inventory.ini

clean: ## destroy terraform infrastructure
	@cd $(TF_DIR) && terraform destroy



play:
	@ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/nginx.yml

build: tr_apply tr_output play