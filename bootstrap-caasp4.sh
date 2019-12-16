eval "$(ssh-agent -s)"
ssh-add
PREFIX="caasp4"
SUFFIX=".cf1"
DOMAIN=".private.jmllabsuse.com"
MASTER1=$PREFIX"-master1"$SUFFIX$DOMAIN
NODE1=$PREFIX"-node1"$SUFFIX$DOMAIN
NODE2=$PREFIX"-node2"$SUFFIX$DOMAIN

ssh-keyscan -t rsa $MASTER1  >> ~/.ssh/known_hosts
ssh-keyscan -t rsa $NODE1  >> ~/.ssh/known_hosts
ssh-keyscan -t rsa $NODE2  >> ~/.ssh/known_hosts

# mount /var/lib/containers in node2 & node1 on the datadisk of 100Gb
# GRUB swapaccount=1
skuba  cluster init --control-plane $MASTER1  caaspV4
cd caaspV4
skuba node bootstrap --sudo --user jmlambert  --target $MASTER1 -v10
skuba node join --role worker --sudo --user jmlambert  --target $NODE1 node1 -v10
skuba node join --role worker --sudo --user jmlambert  --target $NODE2 node2 -v10
export KUBECONFIG=admin.conf
kubectl get nodes
kubectl get pods -n kube-system
