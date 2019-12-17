# caasp4-azure-tf
tf for caasp4 on azurerm
## Prerequisite
- Need for a DNS domain allocated (here jmllabsuse.com as example)
- Change this value in the main.tf file
## Instructions
- Copy the setenvs.sh-example into a setenvs.sh file and fill your own parameters there
- Here : all TF_VAR_ prefixed envs vars will be reusable in TF 
- Copy the reg-suse-jml-script.sh-example into a reg-suse-jml-script.sh file & fill your data 
 -- registration etc
- edit the main.tf to define your ResourceGroup and other preferences
## Terraform validate
To check the syntax of Terraform tf files
## Terraform plan
To plan for the deployment
## Terraform apply
To deploy actually, you will have to agree on the set of actions.
## Terraform destroy
To delete the resources managed by TF.
