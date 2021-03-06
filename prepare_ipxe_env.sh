#!/bin/bash

set -e

K8SVersion=1.5.1
CoreOSInstallationVersion=1185.5.0

# Create necessary directories
mkdir -p /var/www/html/{ipxe,k8s}
mkdir -p /var/www/html/images/{docker,coreos/amd64-usr/${CoreOSInstallationVersion}} /etc/dhcp/template
mkdir -p /var/tftpboot /root/bin

# Add docker repository and install docker
if ! apt-cache policy | grep -q "apt.dockerproject.org"; then
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list
fi
apt-key update
apt-get update
apt-get install -y docker-engine

# Download rkt's hyperkube image
if ! [ -d /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0 ]; then
    mkdir -p /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0
fi
wget -c https://quay.io/c1/aci/quay.io/coreos/hyperkube/v${K8SVersion}_coreos.0/aci/linux/amd64/ -O /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0/hyperkube.aci
wget -c https://quay.io/c1/aci/quay.io/coreos/hyperkube/v${K8SVersion}_coreos.0/aci.asc/linux/amd64/ -O /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0/hyperkube.aci.asc

# Download coreos_production_iso_image.iso to get vmlinuz, cpio.gz and pxelinux.0
wget -c -P /root https://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso
mount /root/coreos_production_iso_image.iso /mnt
cp -f /mnt/coreos/* /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion}
cp -f /mnt/isolinux/pxelinux.0 /var/tftpboot
umount /mnt

# Download ipxe.iso to get ipxe.krn
wget -c -P /root http://boot.ipxe.org/ipxe.iso
mount /root/ipxe.iso /mnt
cp -f /mnt/ipxe.krn /var/tftpboot
umount /mnt

# Download necessary files
wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2
wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2.sig
wget -c -P /var/www/html/soft http://downloads.activestate.com/ActivePython/releases/2.7.10.12/ActivePython-2.7.10.12-linux-x86_64.tar.gz
wget -c -P /var/www/html/soft https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz
wget -c -P /var/www/html/soft https://storage.googleapis.com/kubernetes-release-dev/ci-cross/v1.5.0-alpha.2.421+a6bea3d79b8bba/bin/linux/amd64/kubeadm

docker pull gcr.io/google_containers/hyperkube-amd64:v${K8SVersion}
docker pull gcr.io/google_containers/kube-discovery-amd64:1.0
docker pull gcr.io/google_containers/kubedns-amd64:1.7
docker pull gcr.io/google_containers/exechealthz-amd64:1.1
docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.3
docker pull gcr.io/google_containers/pause-amd64:3.0
docker pull calico/node:v0.22.0
docker pull calico/cni:v1.4.2
docker pull calico/ctl:v0.22.0
docker pull calico/kube-policy-controller:v0.3.0
docker pull quay.io/coreos/pod-checkpointer:b4f0353cc12d95737628b8815625cc8e5cedb6fc
docker pull quay.io/coreos/hyperkube:v${K8SVersion}_coreos.0
docker pull gcr.io/google_containers/dnsmasq-metrics-amd64:1.0
docker pull gcr.io/google_containers/kubedns-amd64:1.9
docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.4

docker save gcr.io/google_containers/hyperkube-amd64:v${K8SVersion} > /var/www/html/images/docker/hyperkube-amd64_v${K8SVersion}.tar
docker save gcr.io/google_containers/kube-discovery-amd64:1.0 > /var/www/html/images/docker/kube-discovery-amd64_1.0.tar
docker save gcr.io/google_containers/kubedns-amd64:1.7 > /var/www/html/images/docker/kubedns-amd64_1.7.tar
docker save gcr.io/google_containers/exechealthz-amd64:1.1 > /var/www/html/images/docker/exechealthz-amd64_1.1.tar
docker save gcr.io/google_containers/kube-dnsmasq-amd64:1.3 > /var/www/html/images/docker/kube-dnsmasq-amd64_1.3.tar
docker save gcr.io/google_containers/pause-amd64:3.0 > /var/www/html/images/docker/pause-amd64_3.0.tar
docker save calico/node:v0.22.0 > /var/www/html/images/docker/node_v0.22.0.tar
docker save calico/cni:v1.4.2 > /var/www/html/images/docker/cni_v1.4.2.tar
docker save calico/ctl:v0.22.0 > /var/www/html/images/docker/ctl_v0.22.0.tar
docker save calico/kube-policy-controller:v0.3.0 > /var/www/html/images/docker/kube-policy-controller_v0.3.0.tar
docker save quay.io/coreos/pod-checkpointer:b4f0353cc12d95737628b8815625cc8e5cedb6fc > /var/www/html/images/docker/pod-checkpointer.tar
docker save quay.io/coreos/hyperkube:v${K8SVersion}_coreos.0 > /var/www/html/images/docker/hyperkube_v${K8SVersion}_coreos.0.tar
docker save gcr.io/google_containers/dnsmasq-metrics-amd64:1.0 > /var/www/html/images/docker/dnsmasq-metrics-amd64_1.0.tar
docker save gcr.io/google_containers/kubedns-amd64:1.9 > /var/www/html/images/docker/kubedns-amd64_1.9.tar
docker save gcr.io/google_containers/kube-dnsmasq-amd64:1.4 > /var/www/html/images/docker/kube-dnsmasq-amd64_1.4.tar

# save all image tar to list
ls -1 /var/www/html/images/docker/ > /var/www/html/images/docker-list

docker run --rm -v /var/www/html/soft:/tmp/bin gcr.io/google_containers/hyperkube-amd64:v${K8SVersion} /bin/sh -c "cp -f /hyperkube /tmp/bin"

iPXE_Server_IP=$1
RouterIP=$2
Subnet=${iPXE_Server_IP%.*}.0
Netmask=255.255.255.0
Range1=${iPXE_Server_IP%.*}.181
Range2=${iPXE_Server_IP%.*}.190
Broadcast=${iPXE_Server_IP%.*}.255
cat > etc/dhcp/dhcpd.conf.tpl << EOF
ddns-update-style none;
option domain-name "example.org";
option domain-name-servers 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet $Subnet netmask $Netmask {
  range $Range1 $Range2;
  option routers $RouterIP;
  option broadcast-address $Broadcast;
  next-server $iPXE_Server_IP;
  filename = "pxelinux.0";
}

host station {
      hardware ethernet MACAddress;
      fixed-address ServerIPAddress;
}
EOF

cat > /var/www/html/ipxe/boot.ipxe << EOF
#!ipxe

set base-url http://${iPXE_Server_IP}/images/coreos/amd64-usr/${CoreOSInstallationVersion}
kernel \${base-url}/vmlinuz cloud-config-url=http://${iPXE_Server_IP}/cloud-configs/ipxe-cloud-config.yml coreos.autologin
initrd \${base-url}/cpio.gz
boot
EOF

docker pull networkboot/dhcpd
docker pull nginx
docker pull cpuguy83/nfs-server
docker pull pghalliday/tftp

cp -f systemd-conf/* /etc/systemd/system
systemctl daemon-reload
for i in nfs-server nginx tftp; do
    systemctl enable $i
    systemctl restart $i
done

rsync -avz root/bin/ /root/bin/
rsync -avz var/www/ /var/www/
rsync -avz var/tftpboot/ /var/tftpboot/
rsync -avz etc/dhcp/ /etc/dhcp/

ethX=$3
WebDir=/var/www/html
sed -i "s/ethX/$ethX/g" /etc/systemd/system/dhcp.service
sed -i "s/K8SVersion/$K8SVersion/g" ${WebDir}/bin/*
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" ${WebDir}/bin/*
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" ${WebDir}/cloud-configs/template/*
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" /var/tftpboot/pxelinux.cfg/by_mac.tpl
sed -i "s/RouterIP/$RouterIP/g" ${WebDir}/cloud-configs/template/*

