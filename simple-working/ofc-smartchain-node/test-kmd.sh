#!/bin/bash
/opt/komodo/komodo/src/komodod -ac_cc=2 -ac_name=IJUICE -ac_pubkey=038afbc819aecfb3d65acdf270f755c9279d69d4a27293f10889264b8bd6c1fae2 -ac_reward=10000 -ac_supply=1000 -addnode=144.76.148.154 -datadir=/var/data/komodo/coindata//IJUICE -rpcallowip=172.29.0.0/24 -rpcallowip=127.0.0.1 -rpcbind=0.0.0.0 -rpcpassword=alsochangeme -rpcport=24708 -rpcuser=changeme -server=1-timeout=18000 -txindex=1 -blocknotify="/opt/komodo/customer-smartchain-nodes-blocknotify/jobs.sh %s" -pubkey=02db69eaad486fb69ac905a771e40b97dcfecbae0a0cc040616fe81a3a05827564 &

