# Sync to test chain: IJUICE
Build the docker image

```
docker build -t ijuice .
```

Then run the container
```
docker run -i -t -p 127.0.0.1:24708:24708 -p 24707:24707 --name ijuice ijuice
```

It will drop you into a bash prompt.

To view log with tail command and see status

```
tail -f /root/.komodo/IJUICE/debug.log
```

To check from cli

```
/root/komodo/src/komodo-cli -ac_name=IJUICE getinfo
```

To check with curl command

```
source /root/.komodo/IJUICE/IJUICE.conf
curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\": \"curltest\", \"method\": \"getinfo\", \"params\": []}" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/
```

Response will be approximately:
```
{"result":{"version":3000000,"protocolversion":170009,"KMDversion":"0.5.3","synced":false,"notarized":0,"prevMoMheight":0,"notarizedhash":"0000000000000000000000000000000000000000000000000000000000000000","notarizedtxid":"0000000000000000000000000000000000000000000000000000000000000000","notarizedtxid_height":"mempool","KMDnotarized_height":0,"notarized_confirms":0,"walletversion":60000,"balance":0.00000000,"blocks":720,"longestchain":33485,"tiptime":1595007430,"difficulty":7.218524397112283,"keypoololdest":1597916599,"keypoolsize":101,"paytxfee":0.00000000,"sapling":61,"timeoffset":0,"connections":1,"proxy":"","testnet":false,"relayfee":0.00000100,"errors":"","CCid":2,"name":"IJUICE","p2pport":24707,"rpcport":24708,"magic":-1565875089,"premine":1000,"reward":"10000","halving":"0","decay":"0","endsubsidy":"0","notarypay":"0"},"error":null,"id":"curltest"}
```
