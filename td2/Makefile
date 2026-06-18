TF_DIR := td2-terraform
ANSIBLE_DIR := td2-ansible
SSH_KEY ?= /root/.ssh/terraform-ipssi
SSH_USER ?= ubuntu
TF := terraform -chdir=$(TF_DIR)
ANSIBLE_INVENTORY := $(ANSIBLE_DIR)/inventory.ini

.PHONY: help pubkey init fmt validate plan apply output inventory ping ansible test-alert alerts destroy clean-local

help:
	@echo "TD2 J2 Suricata - commandes disponibles"
	@echo "  make pubkey       : generer /root/.ssh/terraform-ipssi.pub si besoin"
	@echo "  make init         : terraform init"
	@echo "  make fmt          : terraform fmt"
	@echo "  make validate     : terraform validate"
	@echo "  make plan         : terraform plan"
	@echo "  make apply        : terraform apply"
	@echo "  make inventory    : generer td2-ansible/inventory.ini"
	@echo "  make ping         : tester Ansible"
	@echo "  make ansible      : installer/configurer Suricata"
	@echo "  make test-alert   : generer un ping vers la sonde et verifier l'alerte"
	@echo "  make alerts       : afficher les dernieres alertes Suricata"
	@echo "  make destroy      : supprimer les ressources AWS"

pubkey:
	@test -f $(SSH_KEY) || (echo "Cle privee absente: $(SSH_KEY)" && exit 1)
	@ssh-keygen -y -f $(SSH_KEY) > $(SSH_KEY).pub
	@chmod 600 $(SSH_KEY)
	@chmod 644 $(SSH_KEY).pub
	@echo "Cle publique generee: $(SSH_KEY).pub"

init:
	$(TF) init

fmt:
	$(TF) fmt -recursive

validate:
	$(TF) validate

plan:
	$(TF) plan

apply:
	$(TF) apply

output:
	$(TF) output

inventory:
	@mkdir -p $(ANSIBLE_DIR)
	@BASTION_IP=$$($(TF) output -raw bastion_ip); \
	SONDE_IP=$$($(TF) output -raw sonde_private_ip); \
	printf '[bastion]\n' > $(ANSIBLE_INVENTORY); \
	printf 'bastion ansible_host=%s ansible_user=$(SSH_USER) ansible_ssh_private_key_file=$(SSH_KEY)\n\n' "$$BASTION_IP" >> $(ANSIBLE_INVENTORY); \
	printf '[sondes]\n' >> $(ANSIBLE_INVENTORY); \
	printf 'sonde-suricata ansible_host=%s ansible_user=$(SSH_USER) ansible_ssh_private_key_file=$(SSH_KEY) ansible_ssh_common_args='\''-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %%h:%%p -q -o StrictHostKeyChecking=no -i $(SSH_KEY) $(SSH_USER)@%s"'\''\n' "$$SONDE_IP" "$$BASTION_IP" >> $(ANSIBLE_INVENTORY); \
	echo "Inventaire genere: $(ANSIBLE_INVENTORY)"; \
	cat $(ANSIBLE_INVENTORY)

ping:
	ansible -i $(ANSIBLE_INVENTORY) all -m ping

ansible:
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIR)/install_suricata.yml

test-alert:
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIR)/test_alerte.yml

alerts:
	ansible -i $(ANSIBLE_INVENTORY) sondes -b -m shell -a 'tail -n 50 /var/log/suricata/fast.log || true'

destroy:
	$(TF) destroy

clean-local:
	rm -f $(ANSIBLE_INVENTORY)
	rm -rf $(TF_DIR)/.terraform
