help:           ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dev-init: ## Terraform init for DEV env
	@terraform init -backend-config=env-variables/dev-backend.tfvars -no-color

dev-apply: ## Terraform Apply for DEV env
	@terraform apply -var-file=env-variables/dev.tfvars -var-file=env-variables/dev-backend.tfvars -auto-approve -no-color

dev-destroy: dev-init ## Terraform Apply for DEV env
	@terraform destroy -var-file=env-variables/dev.tfvars -var-file=env-variables/dev-backend.tfvars -auto-approve -no-color

prod-init: ## Terraform init for PROD env
	@terraform init -backend-config=env-variables/prod-backend.tfvars -no-color

prod-apply: ## Terraform Apply for PROD env
	@terraform apply -var-file=env-variables/prod.tfvars -var-file=env-variables/prod-backend.tfvars -auto-approve -no-color

prod-destroy: prod-init ## Terraform Apply for PROD env
	@terraform destroy -var-file=env-variables/prod.tfvars -var-file=env-variables/prod-backend.tfvars -auto-approve -no-color
