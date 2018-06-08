#!/bin/bash
mv /home/centos/kubernetes.repo /etc/yum.repos.d
mv /home/centos/*yml /root
echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.d/99-sysctl.conf
sysctl -p
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
yum install -y docker kubelet kubeadm kubectl kubernetes-cni
sed -i "s/--selinux-enabled //" /etc/sysconfig/docker
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
kubeadm init --pod-network-cidr=10.244.0.0/16
cp /etc/kubernetes/admin.conf /root/
chown root:root /root/admin.conf
export KUBECONFIG=/root/admin.conf
echo "export KUBECONFIG=/root/admin.conf" >>/root/.bashrc
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create -f /root/kube-flannel-rbac.yml
kubectl apply -f /root/kube-flannel.yml
sleep 160
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
kubectl create ns skydive
kubectl create -n skydive -f https://raw.githubusercontent.com/skydive-project/skydive/master/contrib/kubernetes/skydive.yaml
yum -y install git
git clone https://github.com/kubernetes/heapster.git /root/heapster
kubectl create -f /root/heapster/deploy/kube-config/influxdb/
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard.yaml
VERSION="v0.5.0"
yum -y install xorg-x11-xauth virt-viewer wget
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
setenforce 0
kubectl config set-context `kubectl config current-context` --namespace=kube-system
wget https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt.yaml
kubectl create -f kubevirt.yaml
wget https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
mv virtctl-$VERSION-linux-amd64 /usr/bin/virtctl
chmod u+x /usr/bin/virtctl
kubectl config set-context `kubectl config current-context` --namespace=default
docker pull karmab/kcli
echo alias kcli=\'docker run -it --rm -v ~/.kube:/root/.kube:Z -v ~/.ssh:/root/.ssh:Z  -v ~/.kcli:/root/.kcli:Z karmab/kcli\' >> /root/.bashrc
# setsebool -P virt_use_nfs 1
yum -y install nfs-utils
for i in `seq -f "%03g" 1 20` ; do
mkdir /pv$i
echo "/pv$i *(rw,no_root_squash)"  >>  /etc/exports
chcon -t svirt_sandbox_file_t /pv$i
chmod 777 /pv$i
done
exportfs -r
systemctl start nfs ; systemctl enable nfs-server
for i in `seq 1 20` ; do j=`printf "%03d" $i` ; sed "s/001/$j/" /root/nfs.yml | kubectl create -f - ; done
