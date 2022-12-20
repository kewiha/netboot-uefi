#!/bin/bash -e
#downloads and extracts debian ISOs

scriptname="download_debian.sh"
target_path_base="/z/mix/docker/common-netboot/targets/debian"
mount_path="/tmp/isomount"

DEs=( "standard" "gnome" )
flavour=( "nonfree" "nonfree" )
ISO_sources=( "https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current-live/amd64/iso-hybrid/" "https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current-live/amd64/iso-hybrid/" )

for iDE in "${!DEs[@]}" ; do
	target_path="$target_path_base/${flavour[$iDE]}/${DEs[$iDE]}"
	target_subdir_install="$target_path/install"
	target_subdir_live="$target_path/live"

	mkdir -p "$target_subdir_install"
	mkdir -p "$target_subdir_live"

	ISO_path="$(printf '%s\n' "${ISO_sources[$iDE]}/$(curl -s "${ISO_sources[$iDE]}" | grep 'debian.*amd64.*'"${DEs[$iDE]}"'.*.iso' | sed 's/.*href=\"//' | sed 's/.iso.*/.iso/')")"
	ISO_name="$(printf '%s\n' "$ISO_path" | sed 's;.*/;;')"

	### Download and mount latest ISO ###
	#Check if we already have this version downloaded, if not download it
	if [[ "$(ls "$target_path" | grep ^"$ISO_name"$)" == "" ]] ; then
		#Check if we have old ISOs downloaded, if so delete
	        if [[ "$(ls -A "$target_path" | grep '.iso$' )" != "" ]] ; then
        	        rm "$target_path/"*.iso
	        fi
		wget -q --directory-prefix="$target_path" "$ISO_path"
		fresh_ISO="true"
	else
		fresh_ISO="false"
	fi


	mkdir -p "$mount_path"

	#Check if mount_path is empty, if so quit
	if [[ "$(ls -A "$mount_path")" != "" ]] ; then
		printf '%s\n' "$scriptname WARN: $mount_path not empty"
		umount "$mount_path"
		if [[ "$(ls -A "$mount_path")" != "" ]] ; then
			printf '%s\n' "$scriptname ERROR: $mount_path not empty and couldn't empty it"
			exit 1
		fi
	fi

	mount -r -o loop "$target_path/$ISO_name" "$mount_path"

	### Extract Install Components ###
	#Check if install subdir is not empty AND we downloaded a new ISO, delete
	if [[ "$(ls -A "$target_subdir_install")" != "" ]] && [[ "$fresh_ISO" == "true" ]] ; then
		rm -r "$target_subdir_install/"*
	fi
	#if install subdir is empty, copy
	if [[ "$(ls -A "$target_subdir_install")" == "" ]] ; then
		cp -a "$mount_path/"* "$target_subdir_install"
	fi

	### Extract Live Components ###
	#Check if live subdir is not empty, if so delete
	if [[ "$(ls -A "$target_subdir_live")" != "" ]] ; then
		rm -r "$target_subdir_live/"*
	fi

	ln "$target_subdir_install/live/"vmlinuz* "$target_subdir_live/vmlinuz"
        ln "$target_subdir_install/live/"filesystem.squashfs "$target_subdir_live/filesystem.squashfs"
        ln "$target_subdir_install/live/"initrd* "$target_subdir_live/initrd"

	umount "$mount_path"
done


