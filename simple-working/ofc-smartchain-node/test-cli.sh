#!/bin/bash
CHAIN=IJUICE
/opt/komodo/komodo/src/komodo-cli -datadir=/var/data/komodo/coindata/${CHAIN} -conf=/var/data/komodo/coindata/${CHAIN}/${CHAIN}.conf -ac_name=${CHAIN} "$@"


