# caasp4-azure-tf
tf resources for caasp4 deployment on azurerm
![Architecture Diagram](caasp4%20on%20azure.jpg?raw=true "Architecture Diagram")
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
# Files content
## setenvs.sh-example
Setup your variables content
## caasp4.tf
## keyset.pub
Set of public keys to inject in all nodes vms
## main.tf-example
File to copy as main.tf and add your own values (registrations etc)
## maindns.tf
Create DNS domains public & private
## mainlb.tf
Create the Load balancer resources & rules
## reg-suse-jml-script.sh-example
Script to copy as reg-suse-jml-script.sh and add your SUSE reg elements & other params
## swap.sh
Script to set "cgroup_enable=memory swapaccount=1"
## nfsserver.sh
Mount newly attached data disk and for the admin node, start a nfs server there 
## bootstrap-caasp4.sh
Bootstrap CaaSP4 node with skuba
Check the DNS names inside if you change other deployment urls

