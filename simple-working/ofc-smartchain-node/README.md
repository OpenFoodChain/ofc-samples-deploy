Place this file somewhere on filesystem.

Make sure it is executable.

Pass in -blocknotify=/path/to/this/script

The node needs to be funded and wallet loaded.

The script needs to know IP:port of the rpc interface as well
as rpcuser and rpcpassword.

For testing the address is hardcoded.

== Install
System requirements
```
sudo apt install php php-gmp jq
```
Git submodule bitcoin ECDSA
```
git clone https://github.com/the-new-fork/customer-smartchain-nodes-blocknotify
git submodule init
git submodule update --init --recursive
```
