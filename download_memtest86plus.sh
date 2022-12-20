#!/bin/bash -e
#downloads and extracts memtest86plus

scriptname="download_memtest86plus.sh"
target_path_base="/z/mix/docker/common-netboot/targets/memtest86plus"
mount_path="/tmp/isomount"

DEs=( "64" )
flavour=( "linux_nogrub" )
ISO_sources=( "https://memtest.org/" )

for iDE in "${!DEs[@]}" ; do
	target_path="$target_path_base/${flavour[$iDE]}/${DEs[$iDE]}"
	target_subdir="$target_path/extract"

	mkdir -p "$target_subdir"

	ZIP_path="$(printf '%s\n' "${ISO_sources[$iDE]}$(curl -s "${ISO_sources[$iDE]}" | grep 'mt86plus_.*'"${DEs[$iDE]}"'.iso.zip.*'"Linux ISO (64 bits)</a>" | sed 's/.*href=\"//' | sed 's/.iso.zip.*/.iso.zip/')")"
	ZIP_name="$(printf '%s\n' "$ZIP_path" | sed 's;.*/;;')"
	ISO_name="mt86plus64.iso"

	### Download and mount latest ISO ###
	#Check if we already have this version downloaded, if not download it
	if [[ "$(ls "$target_path" | grep ^"$ZIP_name"$)" == "" ]] ; then
		#Check if we have old ISOs downloaded, if so delete
	        if [[ "$(ls -A "$target_path" | grep '.iso$' )" != "" ]] ; then
        	        rm "$target_path/"*.iso
	        fi
		#Check if we have old ISO.zips downloaded, if so delete
                if [[ "$(ls -A "$target_path" | grep '.iso.zip$' )" != "" ]] ; then
                        rm "$target_path/"*.iso.zip
                fi
		wget -q --directory-prefix="$target_path" "$ZIP_path"
		unzip -q -u "$target_path/$ZIP_name" -d "$target_path"
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

	### Extract Components ###
	#Check if subdir is not empty AND we downloaded a new ISO, delete
	if [[ "$(ls -A "$target_subdir")" != "" ]] && [[ "$fresh_ISO" == "true" ]] ; then
		rm -r "$target_subdir/"*
	fi
	#if subdir is empty, copy
	if [[ "$(ls -A "$target_subdir")" == "" ]] ; then
		cp -a "$mount_path/"* "$target_subdir"
	fi

	umount "$mount_path"
done


