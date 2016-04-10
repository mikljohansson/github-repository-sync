#!/bin/bash
set -e

trap '{ exit 1; }' SIGINT
trap '{ exit 0; }' SIGTERM

# Decrypt secrets
if [ "$SERVICE_PUBLIC_KEY" != "" ]; then
    SECRETS=$(secretary decrypt -e --service-key=/service/keys/service-private-key.pem)
else
    SECRETS=$(secretary decrypt -e)
fi

eval "$SECRETS"
unset SECRETS

# Write SSH key
if [ "$SSH_KEY" != "" ]; then
	echo "Using SSH key from environment"
	echo "$SSH_KEY" > "/root/.ssh/id_rsa"
	chmod 0600 /root/.ssh/id_rsa
fi

# Run sync script
while [ "1" != "2" ]; do
	/sync.sh & wait
	sleep 5 & wait
done
