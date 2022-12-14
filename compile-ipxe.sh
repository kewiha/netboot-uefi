#!/bin/bash -e
#based on https://rpi4cluster.com/pxe/ipxe/

#get pre-requisite packages
apt update && apt install git make gcc binutils
#apt install perl mkisofs syslinux liblzma-dev isolinux mtools
	#not sure if needed

cd ~/
git clone git://git.ipxe.org/ipxe.git


### ipxe/src/config/general.h ###
#Enable functionality I may want
defineme=( "DOWNLOAD_PROTO_HTTPS" "DOWNLOAD_PROTO_NFS" "SANBOOT_PROTO_ISCSI" "SANBOOT_PROTO_HTTP" "IMAGE_SCRIPT" "IMAGE_EFI" "REBOOT_CMD" "POWEROFF_CMD" "PING_CMD" "IPSTAT_CMD" ) 
for ivar in "${!defineme[@]}" ; do
	sed -i 's;.*'"${defineme[$ivar]}"'.*;#define\t'"${defineme[$ivar]}"';' ~/ipxe/src/config/general.h
done

#Disable functionality I probably won't want
undefineme=( "NET_PROTO_STP" "NET_PROTO_EAPOL" "CRYPTO_80211_WEP" "CRYPTO_80211_WPA" "CRYPTO_80211_WPA2" "IMAGE_MULTIBOOT" "IMAGE_DER" "IMAGE_PEM" "VNIC_IPOIB" ) 
for ivar in "${!undefineme[@]}" ; do
	sed -i 's;.*'"${undefineme[$ivar]}"'.*;#undefine\t'"${undefineme[$ivar]}"';' ~/ipxe/src/config/general.h
done

#It's not clear to me if '#undef...' and '//#define' have the same effect. The intended effect to save space in ipxe.efi so 'make' works.

### ipxe/embed.ipxe ###
#copies the following lines to ~/ipxe/embed.ipxe, excluding the first and last lines (i.e. with EOF in them)
cat << EOF >~/ipxe/embed.ipxe
#!ipxe
dhcp && goto netboot || goto dhcperror

:dhcperror
prompt --key s --timeout 10000 DHCP failed, hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot

:netboot
chain tftp://${next-server}/main.ipxe ||
prompt --key s --timeout 10000 Chainloading failed, hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot
EOF
#A key part of this embed.ipxe is that you're hard-coding in tftp://${next-server}/main.ipxe as the iPXE script location that ipxe.efi will always try to load
	#make sure your first script is called main.ipxe, and is in the root of the tftp server that your dhcp server advertises as the "next server"


### compile ipxe.efi ###
cd ~/ipxe/src
make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe

### check if ipxe.efi exists and report its full path
if [[ -f ~/ipxe/src/bin-x86_64-efi/ipxe.efi ]] ; then
	printf '%s\n' "ipxe exists at $(stat --format=%n ~/ipxe/src/bin-x86_64-efi/ipxe.efi)"
	printf '%s\n' "success(?)"
fi

