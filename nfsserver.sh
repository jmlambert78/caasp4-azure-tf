#!/bin/bash
HOSTNAME=$(hostname)
if [[ $HOSTNAME == *"admin"* ]]; then 
	DEVDSK=$(parted -l 2>&1|grep Error |gawk '{gsub(":","",$2);print $2}')
	mkfs.ext2 -L datapartition $DEVDSK
        mkdir /srv/nfsstore
	mount -o defaults $DEVDSK /srv/nfsstore
	lsblk -fs|awk ' /nfsstore/{printf( "UUID=%s    %s   %s    defaults   0 2\n",$4,$NF,$2)}' >> /etc/fstab
	chmod 777 /srv/nfsstore
	echo '/srv/nfsstore       *(rw,no_root_squash,sync,no_subtree_check)' >/etc/exports
        systemctl enable nfsserver
	systemctl start nfsserver;
fi
# case of nodes, datadisk to attach to /var/lib/containers
if [[ $HOSTNAME == *"node"* ]]; then 
	DEVDSK=$(parted -l 2>&1|grep Error |gawk '{gsub(":","",$2);print $2}')
	mkfs.ext2 -L datapartition $DEVDSK
	mkdir /var/lib/containers
	mount -o defaults $DEVDSK /var/lib/containers
	lsblk -fs|awk ' /containers/{printf( "UUID=%s    %s   %s    defaults   0 2\n",$4,$NF,$2)}' >> /etc/fstab;
fi
