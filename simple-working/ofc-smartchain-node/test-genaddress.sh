#!/bin/bash
RANDOM_MESSAGE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo $RANDOM_MESSAGE
ADDRESS=$(php genaddressonly.php $${RANDOM_MESSAGE} | jq -r '.address')
echo $ADDRESS
