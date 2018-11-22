#!/usr/bin/env bash

# Get certs will try a maximum of 3 fail attempts
cd /opt/dehydrated/
count=0
false
while [ $? -ne 0 ] && [ $count -lt 3 ]
do
	if [ $count -ne 0 ]
	then
		echo "SLEEPING FOR 60 SECONDS BEFORE RETRY"
		sleep 60
	fi
	let count=count+1
	echo "SSL cert try: $count"
	./dehydrated -c -f config
done
if [ $? -ne 0 ]
then
	echo "SSL CERT FAILED!!!"
	exit 1
fi
