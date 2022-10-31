#!/bin/bash

rpcuser=$(env  | grep KOMODO_SMARTCHAIN_NODE_USERNAME | cut -d '=' -f2-)
rpcpassword=$(env  | grep KOMODO_SMARTCHAIN_NODE_PASSWORD | cut -d '=' -f2-)
rpcport=$(env  | grep KOMODO_SMARTCHAIN_NODE_RPC_PORT | cut -d '=' -f2-)
komodo_node_ip=127.0.0.1

CHAIN_SYNC=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\": \"syncquery\", \"method\": \"getinfo\", \"params\": []}" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result.longestchain - .result.blocks as $diff | $diff')
echo "Out of sync by ${CHAIN_SYNC} blocks"

if [ $CHAIN_SYNC -lt ${BLOCKNOTIFY_CHAINSYNC_LIMIT} ] ; then
	echo "Chain sync ok. Working..."
else
	echo "Chain out of sync by ${CHAIN_SYNC} blocks. If counting down, syncing. See you again next block, goodbye..."
	# TODO send alarm
	exit
fi

