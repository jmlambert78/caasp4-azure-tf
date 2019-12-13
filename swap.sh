sudo sed -i -r 's|^(GRUB_CMDLINE_LINUX=)\"\"|\1\" cgroup_enable=memory swapaccount=1\"|' /etc/default/grub
sudo  sed -i -r 's|^(GRUB_CMDLINE_LINUX_DEFAULT=)\"(.*.)\"|\1\"\2  mitigations=auto quiet crashkernel=128M,high crashkernel=80M,low\"|' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
