**MASTER** branch is useless for this repo - use the latest jamjuiceX, stagingjuice

## Notes:
- Branches:
  * stagingjuice for the staging environment chain
  * jamjuice for the multiple orgs on single server scripts
  * demojuice for connecting to the demo chain
  * master for keeping master branch of submodules
- To run: `docker-compose up`.
- The data from juicy chain will be saved locally to `./ijuice-komodo-node/data`, blockchain data
will not be lost when the `ijuice-komodo-node` container is restarted or deleted.
- Environment variables which are needed accross different docker-compose services are in `.env`.
- All other environment variables are defined explicitly in the `docker-compose` file.
- No config file is used, all parametsers are passed as arguments to the komodo binary.


## Some useful commands, based on current environment variables
- from terminal: `docker exec simple-working_ijuice-komodo-node_1 tail -f /var/data/komodo/coindata/IJUICE/debug.log`.
- from the ijuice-komodo-node: `curl --user changeme:alsochangeme --data '{"method": "getinfo"}' http://127.0.0.1:24708`.
- rebuild blocknotify-python `docker rm simple-working_blocknotify-python_1 ; docker-compose up -d --no-deps --build blocknotify-python`
- test blocknotify-python `docker start simple-working_blocknotify-python_1` and watch it in the docker-compose window
