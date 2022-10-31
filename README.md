# deploy-samples

- Sample Django + DB: This uses postgres, but we will be using mariadb. Pretty standard. Apache in front of the app server.
    - Expose web port to outside world (allow by host/network)
    - For public facing web app (and team bali), expose web port to 0.0.0.0
- Sample Blockchain Only v1: This is komodod (komodo daemon) built in ubuntu 16 with no extras.
    - entrypoint.sh sets up the config file in the correct directory
    - start-komodod.sh passes the args/"parameters" <-- the parameters are all that changes for startup of different "smart chains"
    - expose RPC port strictly to the most limited access as possible
    - expose P2P port to 0.0.0.0
- Sample Blockchain + Electrumx (SPV Mode = Broadcast Server for lite wallets or signed transactions)
    - same as (2) + electrumx port 50001 and 50002 only exposed to lite wallets within pod/network
- Sample Blockchain + Electrumx TCP App + Lite Wallet executable + Web Service + DB
    - same as (3)
    - expose web service as per (1)
- Sample Blockchain + Explorer Web App (+Apache/nginx)
    - same as (2)
    - expose web url of explorer web-app
