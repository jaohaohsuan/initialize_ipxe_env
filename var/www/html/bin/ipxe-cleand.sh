mkdir -p /mnt/{nfs,rootfs/boot}
mount iPXE_Server_IP:/pxelinux.cfg /mnt/nfs

# Bind NIC device to ethX
mount /dev/sda6 /mnt/rootfs/boot
echo set linux_append="net.ifnames=0 biosdevname=0" > /mnt/rootfs/boot/grub.cfg

mac=`ifconfig | sed -n '/192.168/,+2p' | tail -n 1 | awk '{print $2}'`
macd=01-`echo $mac | tr ':' '-'`

cd /mnt/nfs
rm $macd

reboot
