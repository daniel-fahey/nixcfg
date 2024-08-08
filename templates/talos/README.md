```
packer init . && packer build .

terraform init
terraform plan
terraform apply

terraform output --raw kubeconfig | tee .kube/config
terraform output --raw talosconfig | tee .talos/config
```