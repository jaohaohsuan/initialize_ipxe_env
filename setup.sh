#!/bin/bash

set -e

# Create necessary directories
mkdir -p /var/www/html/images/{docker,coreos/amd64-usr/1185.3.0} /etc/dhcp/template
mkdir -p /var/tftpboot

if ! apt-cache policy | grep -q "apt.dockerproject.org"; then
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list
fi

apt-key update
apt-get update
apt-get install -y docker-engine

# Install rkt
if ! dpkg -l rkt > /dev/null 2>&1; then
    wget -c -P /tmp https://github.com/coreos/rkt/releases/download/v1.18.0/rkt_1.18.0-1_amd64.deb
    dpkg -i /tmp/rkt_1.18.0-1_amd64.deb
fi

# Fetch rkt's hyperkube image
rkt --trust-keys-from-https=true fetch quay.io/coreos/hyperkube:v1.4.6_coreos.0
rkt image export --overwrite quay.io/coreos/hyperkube /var/www/html/images/rkt/hyperkube/v1.4.6_coreos.0/hyperkube.aci

# Download necessary files
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 https://stable.release.core-os.net/amd64-usr/1185.3.0/coreos_production_image.bin.bz2
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 https://stable.release.core-os.net/amd64-usr/1185.3.0/coreos_production_image.bin.bz2.sig
wget -c -P /var/www/html/soft http://downloads.activestate.com/ActivePython/releases/2.7.10.12/ActivePython-2.7.10.12-linux-x86_64.tar.gz
wget -c -P /var/www/html/soft https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz
wget -c -P /var/www/html/soft https://storage.googleapis.com/kubernetes-release-dev/ci-cross/v1.5.0-alpha.2.421+a6bea3d79b8bba/bin/linux/amd64/kubeadm
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
wget -c -P /var/www/html/images/coreos/amd64-usr/1185.3.0 http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
wget -c -P /var/tftpboot http://boot.ipxe.org/undionly.kpxe

docker pull gcr.io/google_containers/hyperkube-amd64:v1.4.6
docker pull gcr.io/google_containers/kube-discovery-amd64:1.0
docker pull gcr.io/google_containers/kubedns-amd64:1.7
docker pull gcr.io/google_containers/exechealthz-amd64:1.1
docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.3
docker pull gcr.io/google_containers/pause-amd64:3.0
docker pull calico/node:v0.22.0
docker pull calico/cni:v1.4.2
docker pull calico/ctl:v0.22.0
docker pull calico/kube-policy-controller:v0.3.0

docker save gcr.io/google_containers/hyperkube-amd64:v1.4.6 > /var/www/html/images/docker/hyperkube-amd64_v1.4.6.tar
docker save gcr.io/google_containers/kube-discovery-amd64:1.0 > /var/www/html/images/docker/kube-discovery-amd64_1.0.tar
docker save gcr.io/google_containers/kubedns-amd64:1.7 > /var/www/html/images/docker/kubedns-amd64_1.7.tar
docker save gcr.io/google_containers/exechealthz-amd64:1.1 > /var/www/html/images/docker/exechealthz-amd64_1.1.tar
docker save gcr.io/google_containers/kube-dnsmasq-amd64:1.3 > /var/www/html/images/docker/kube-dnsmasq-amd64_1.3.tar
docker save gcr.io/google_containers/pause-amd64:3.0 > /var/www/html/images/docker/pause-amd64_3.0.tar
docker save calico/node:v0.22.0 > /var/www/html/images/docker/node_v0.22.0.tar
docker save calico/cni:v1.4.2 > /var/www/html/images/docker/cni_v1.4.2.tar
docker save calico/ctl:v0.22.0 > /var/www/html/images/docker/ctl_v0.22.0.tar
docker save calico/kube-policy-controller:v0.3.0 > /var/www/html/images/docker/kube-policy-controller_v0.3.0.tar

docker run --rm -v /var/www/html/soft:/tmp/bin gcr.io/google_containers/hyperkube-amd64:v1.4.6 /bin/sh -c "cp -f /hyperkube /tmp/bin"

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
  if exists user-class and option user-class = "iPXE" {
    filename = "ClientMACAddr.ipxe";
  } else {
    filename = "undionly.kpxe";
  }
}

host station {
      hardware ethernet ClientMACAddr;
      fixed-address ClientIPAddr;
}
EOF

cat > /var/tftpboot/coreos.tpl << EOF
#!ipxe

set base-url http://${iPXE_Server_IP}/images/coreos/amd64-usr/1185.3.0
kernel \${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=http://${iPXE_Server_IP}/cloud-configs/ipxe-cloud-config.yml coreos.autologin
initrd \${base-url}/coreos_production_pxe_image.cpio.gz
boot
EOF

docker pull networkboot/dhcpd
docker pull nginx
docker pull cpuguy83/nfs-server
docker pull pghalliday/tftp

ethX=$3
sed -i "s/ethX/$ethX/g" systemd-conf/dhcp.service
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" var/www/html/bin/coreos-installd.sh
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" var/www/html/bin/ipxe-cleand.sh
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" var/www/html/cloud-configs/template/master-coreos-cloud-config.yml
sed -i "s/RouterIP/$RouterIP/g" var/www/html/cloud-configs/template/master-coreos-cloud-config.yml
sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" var/www/html/cloud-configs/template/ipxe-cloud-config.yml

cp -f systemd-conf/* /etc/systemd/system
for i in dhcp nfs-server nginx tftp; do
    systemctl enable $i
    systemctl start $i
done

rsync -avz root/bin/ /root/bin/
rsync -avz var/www/ /var/www/
rsync -avz etc/dhcp/ /etc/dhcp/