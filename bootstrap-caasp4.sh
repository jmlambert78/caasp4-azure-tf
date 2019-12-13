eval "$(ssh-agent -s)"
ssh-add
ssh caasp4tf-master1-vm.private.jmllabsuse.com ls
ssh caasp4tf-node1-vm.private.jmllabsuse.com ls
ssh caasp4tf-node2-vm.private.jmllabsuse.com ls
# mount /var/lib/containers in node2 & node1 on the datadisk of 100Gb
# GRUB swapaccount=1
skuba  cluster init --control-plane caasp4tf-master1-vm.private.jmllabsuse.com  caaspV4
cd caaspV4
skuba node bootstrap --sudo --user jmlambert --ignore-preflight-errors="all" --target caasp4tf-master1-vm.private.jmllabsuse.com master1 -v10
skuba node join --role worker --sudo --user jmlambert --ignore-preflight-errors="all" --target caasp4tf-node1-vm.private.jmllabsuse.com node1 -v10
skuba node join --role worker --sudo --user jmlambert --ignore-preflight-errors="all" --target caasp4tf-node2-vm.private.jmllabsuse.com node2 -v10
export KUBECONFIG=admin.conf
kubectl get nodes
kubectl get pods -n kube-system
