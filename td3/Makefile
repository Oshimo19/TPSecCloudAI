TF_DIR=td-aws

.PHONY: init fmt validate plan apply destroy outputs site-url clean test-url

init:
	terraform -chdir=$(TF_DIR) init

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

outputs:
	terraform -chdir=$(TF_DIR) output

site-url:
	terraform -chdir=$(TF_DIR) output -raw site_url

test-url:
	curl -I $$(terraform -chdir=$(TF_DIR) output -raw site_url)

clean:
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/terraform.tfstate $(TF_DIR)/terraform.tfstate.backup
