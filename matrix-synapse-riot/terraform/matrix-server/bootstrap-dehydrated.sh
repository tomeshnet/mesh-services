#!/usr/bin/env bash

# Get certs will try a maximum of 3 fail attempts
cd /opt/dehydrated/
count=0
false
while [ $? -ne 0 ] && [ $count -lt 3 ]
do
	if [ $count -ne 0 ]
	then
		echo "Waiting for 60 seconds before retrying"
		sleep 60
	fi
	if [ $count -eq 0 ]
	then
	    	echo "Requesting SSL certificate"
	else
		echo "Requesting SSL certificate (retry: $count)"
	fi
	let count=count+1
	./dehydrated -c -f config
done
if [ $? -ne 0 ]
then
	echo "Failed to request SSL certificate"
	exit 1
fi
