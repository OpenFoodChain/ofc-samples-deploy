#!/bin/bash
mkdir -p /root/.komodo/IJUICE
echo '#generated file from entrypoint.sh
rpcuser=changeuser
rpcpassword=changepassword
rpcport=24708
rpcallowip=127.0.0.1
rpcallowip=172.17.0.1
timeout=18000
txindex=1
server=1
daemon=1' > /root/.komodo/IJUICE/IJUICE.conf

echo "Starting screen"
/usr/bin/screen -dmS blockchain bash -c 'cd /root;./start-ijuice.sh; exec bash'

/bin/bash
