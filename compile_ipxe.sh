#!/bin/bash -e
#based on https://rpi4cluster.com/pxe/ipxe/

scriptname="compile_ipxe.sh"
working_dir="/tmp/compile_ipxe"
	#Change to somewhere in /tmp????

#get pre-requisite packages
apt update -qq
apt install -yqq git make gcc binutils
#apt install perl mkisofs syslinux liblzma-dev isolinux mtools
	#not sure if needed

mkdir -p "$working_dir"
cd "$working_dir"

#clear ipxe folder if it exists
if [[ -d "$working_dir/ipxe" ]] ; then
	rm -r "$working_dir/ipxe"
fi

git clone git://git.ipxe.org/ipxe.git


### ipxe/src/config/general.h ###
#Enable functionality I may want
#defineme=( "DOWNLOAD_PROTO_HTTPS" "DOWNLOAD_PROTO_NFS" "SANBOOT_PROTO_ISCSI" "SANBOOT_PROTO_HTTP" "IMAGE_SCRIPT" "IMAGE_EFI" "REBOOT_CMD" "POWEROFF_CMD" "PING_CMD" "IPSTAT_CMD" )
defineme=( "DOWNLOAD_PROTO_TFTP" "DOWNLOAD_PROTO_HTTP" "DOWNLOAD_PROTO_HTTPS" "DOWNLOAD_PROTO_NFS" "REBOOT_CMD" "POWEROFF_CMD" "PING_CMD" "IPSTAT_CMD" )
for ivar in "${!defineme[@]}" ; do
	sed -i 's;.*'"${defineme[$ivar]}"'.*;#define\t'"${defineme[$ivar]}"';' "$working_dir/ipxe/src/config/general.h"
done

#Disable functionality I probably won't want
#undefineme=( "NET_PROTO_STP" "NET_PROTO_EAPOL" "CRYPTO_80211_WEP" "CRYPTO_80211_WPA" "CRYPTO_80211_WPA2" "IMAGE_MULTIBOOT" "IMAGE_DER" "IMAGE_PEM" "VNIC_IPOIB" )
undefineme=( "NET_PROTO_FCOE" "NET_PROTO_STP" "NET_PROTO_LACP" "NET_PROTO_EAPOL" "DOWNLOAD_PROTO_FTP" "DOWNLOAD_PROTO_SLAM" "CRYPTO_80211_WEP" "CRYPTO_80211_WPA" "CRYPTO_80211_WPA2" "IMAGE_PNG" "IMAGE_DER" "IMAGE_PEM" "IWMGMT_CMD" "IBMGMT_CMD" "FCMGMT_CMD" "SANBOOT_CMD" "IMAGE_ARCHIVE_CMD" "VNIC_IPOIB" )
for ivar in "${!undefineme[@]}" ; do
	sed -i 's;.*'"${undefineme[$ivar]}"'.*;#undef\t'"${undefineme[$ivar]}"';' "$working_dir/ipxe/src/config/general.h"
done

#It's not clear to me if '#undef...' and '//#define' have the same effect. The intended effect to save space in ipxe.efi so 'make' works.

### ipxe/embed.ipxe ###
#A key part of this embed.ipxe is that you're hard-coding in tftp://${next-server}/main.ipxe as the iPXE script location that ipxe.efi will always try to load
	#make sure your first script is called main.ipxe, and is in the root of the tftp server that your dhcp server advertises as the "next server"


### compile ipxe.efi ###
cd "$working_dir/ipxe/src"
make bin-x86_64-efi/ipxe.efi EMBED="$working_dir/embed.ipxe"

### check if ipxe.efi exists and report its full path
if [[ -f "$working_dir/ipxe/src/bin-x86_64-efi/ipxe.efi" ]] ; then
	printf '%s\n' "$scriptname: ipxe exists at $(stat --format=%n $working_dir/ipxe/src/bin-x86_64-efi/ipxe.efi)"
	printf '%s\n' "$scriptname: success(?)"
fi

