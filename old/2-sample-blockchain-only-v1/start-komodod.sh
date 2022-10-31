#!/bin/bash

# If BTC_PUBKEY variable is not empty string and no arguments were passed to container, start mining with pubkey
if [ -n "${BTC_PUBKEY}" -a -n "${KOMODO_ARGS}" ]; then
  echo "Starting komodod with these arguments:"
  echo "komodod -gen -genproclimit=3 -notary -pubkey="${BTC_PUBKEY}" ${KOMODO_ARGS}"
  exec komodod -gen -genproclimit=3 -notary -minrelaytxfee=0.000035 -opretmintxfee=0.004 -pubkey="${BTC_PUBKEY}" ${KOMODO_ARGS}

# We do not have pubkey yeti and no arguments passed to container
elif [ -z "${BTC_PUBKEY}" -a -n "${KOMODO_ARGS}" ]; then
  exec komodod ${KOMODO_ARGS}

# Some arguments were passed
# elif [ $# -ne 0 ]; then
elif [ -z "${KOMODO_ARGS}" ]; then
  # Pass all commands which were passes as commands to container
  exec "$@"
fi
