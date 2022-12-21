#!/bin/bash -e
#Runs compile-ipxe.sh in a docker container then copies ipxe.efi to the netboot directory
#Assumes:
	#you already have docker set up and running, AND use systemd
		#If you don't, consider running compile-ipxe.sh directly or boot from a live debian ISO and run it there
	#compile-ipxe.sh is in the current directory

scriptname="docker_compile_ipxe.sh"
working_dir="/tmp/compile_ipxe/"
target_path_base="/z/mix/docker/common-netboot/"
container=tmp-compile-ipxe
image=library/debian:stable-slim

#checks docker is running
if [[ "$(systemctl is-active docker)" != "active" ]] ; then
	printf '%s\n' "ERROR: docker isn't running or systemd is not being used"
	exit 1
fi

#check if docker container name is already in use
if [[ "$(docker ps --filter NAME="$container" | grep -c "")" != "1" ]] ; then
        printf '%s\n' "ERROR: docker container called $container already exists"
        exit 1
fi


#Create docker container
docker run -d \
	--name=$container \
	--restart unless-stopped \
        $image bash -c "sleep 360000"
	--cpus 1
	#move these above if network issues encountered
	#-h $container \
	#-e TZ=America/Toronto \
        #--network=$(cat /z/mix/st/t1/a/ip.txt | grep $container | sed 's/.*macvlan/macvlan/' | sed 's/[[:space:]].*//g' ) \
        #--ip=$(cat /z/mix/st/t1/a/ip.txt | grep $container | awk '{print $1}') \

#copy compile-ipxe.sh and embed.ipxe to container
docker exec -it "$container" bash -c "mkdir -p $working_dir"
docker cp compile_ipxe.sh "$container":/compile_ipxe.sh
docker cp embed.ipxe "$container":"$working_dir/embed.ipxe"

#run compile-ipxe.sh
docker exec -it $container bash -c "chmod -R 777 /compile_ipxe.sh && /compile_ipxe.sh > /dev/null"

#extract ipxe.efi
docker cp "$container":"$working_dir/ipxe/src/bin-x86_64-efi/ipxe.efi" ipxe.efi.new

#destroy container
docker rm -f $container

#rename ipxe.efi.new to ipxe.efi and move it in place
mv ipxe.efi.new "$target_path_base/ipxe.efi"
chmod 644 "$target_path_base/ipxe.efi"












