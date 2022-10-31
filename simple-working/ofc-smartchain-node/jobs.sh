#!/bin/bash

rpcuser=$(env  | grep IJUICE_KOMODO_NODE_USERNAME | cut -d '=' -f2-)
rpcpassword=$(env  | grep IJUICE_KOMODO_NODE_PASSWORD | cut -d '=' -f2-)
rpcport=$(env  | grep IJUICE_KOMODO_NODE_RPC_PORT | cut -d '=' -f2-)
komodo_node_ip=127.0.0.1

# TODO modulo 100 blocks
# echo "Using $komodo_node_ip:$rpcport with $rpcuser:$rpcpassword"

THIS_NODE_PUBKEY=$(env  | grep THIS_NODE_PUBKEY | cut -d '=' -f2-)
THIS_NODE_WIF=$(env  | grep THIS_NODE_WIF | cut -d '=' -f2-)
THIS_NODE_WALLET=$(env  | grep THIS_NODE_WALLET | cut -d '=' -f2-)

# echo "Using node wallet ${THIS_NODE_WALLET}"

# TODO modulo 100 blocks
IS_MINE=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\": \"isminequery\", \"method\": \"validateaddress\", \"params\": [\"${THIS_NODE_WALLET}\"]}" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result.ismine')
if [ "${IS_MINE}" == "false" ] ; then
	curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\": \"importwif\", \"method\": \"importprivkey\", \"params\": [\"${THIS_NODE_WIF}\"]}" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/
fi

BLOCKNOTIFY_CHAINSYNC_LIMIT=$(env  | grep BLOCKNOTIFY_CHAINSYNC_LIMIT | cut -d '=' -f2-)
HOUSEKEEPING_ADDRESS=$(env  | grep HOUSEKEEPING_ADDRESS | cut -d '=' -f2-)

# echo "Chain out-of-sync limit: ${BLOCKNOTIFY_CHAINSYNC_LIMIT}"

# TEST_DATA=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9+/=' | fold -w 100 | head -n 1)

###############################################################################

# START HOUSEKEEPING

# we send this amount to an address for housekeeping
# update by 0.0001 (manually, if can be done in CI/CD, nice-to-have not need-to-have) (MYLO)
# house keeping address is list.json last entry during dev
SCRIPT_VERSION=0.00010005

CHAIN_SYNC=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\": \"syncquery\", \"method\": \"getinfo\", \"params\": []}" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result.longestchain - .result.blocks as $diff | $diff')
echo "Out of sync by ${CHAIN_SYNC} blocks"

if [ $CHAIN_SYNC -lt ${BLOCKNOTIFY_CHAINSYNC_LIMIT} ] ; then
	echo "Chain sync ok. Working..."
else
	echo "Chain out of sync by ${CHAIN_SYNC} blocks. If counting down, syncing. Try next block, goodbye..."
	# TODO send alarm
	exit
fi


# TODO modulo block number (MYLO)

# send a small amount (SCRIPT_VERSION) for HOUSEKEEPING_ADDRESS from each organization
#############################
# info: for external documentation then remove from here
# one explorer url to check is
# IJUICE  http://seed.juicydev.coingateways.com:24711/address/RS7y4zjQtcNv7inZowb8M6bH3ytS1moj9A
# POS95   http://seed.juicydev.coingateways.com:54343/address/RS7y4zjQtcNv7inZowb8M6bH3ytS1moj9A
#############################
# send SCRIPT_VERSION, increment by 0.00000001 for each update
# curl -s --user $rpcuser:$rpcpassword  --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"housekeeping1\", \"method\": \"sendtoaddress\", \"params\": [\"${HOUSEKEEPING_ADDRESS}\", ${SCRIPT_VERSION}, \"\", \"\"] }" -H "content-type: text/plain;" http://$komodo_node_ip:$rpcport/
#############################

# END OF HOUSEKEEPING

###############################################################################

###############################################################################

# START JCF IMPORT API INTEGRITY CHECKS

# JCF is the only part of script that refers to BATCH.
# development of new partners can use RAW_REFRESCO-like variables

###########################
# organization R-address = $1
# raw_json import data in base64 = $2
# batch record import database id(uuid) = $3
###########################
function import-jcf-batch-integrity-pre-process {
    # integrity-before-processing , create blockchain-address for the import data from integration pipeline
    # r_address has a database constraint for uniqueness.  will fail if exists
    # signmessage, genkomodo.php
    # update batches-api with "import-address"
    # send "pre-process" tx to "import-address"
    local WALLET=$1
    local DATA=$2
    echo $DATA
    local IMPORT_ID=$3
    echo "Checking import id: ${IMPORT_ID}"
    # no wrap base64 from https://superuser.com/a/1225139
    local SIGNED_DATA=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"signrawjson\", \"method\": \"signmessage\", \"params\": [\"${WALLET}\", \"${DATA}\"] }" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result' | base64 -w 0) # | sed 's/\=//')
    echo "signed data: ${SIGNED_DATA}"
    local INTEGRITY_ADDRESS=$(php ${BLOCKNOTIFY_DIR}genaddressonly.php $SIGNED_DATA | jq -r '.address')
    echo "INTEGRITY_ADDRESS will be ${INTEGRITY_ADDRESS}"
    # IMPORTANT!  this next POST will fail if the INTEGRITY_ADDRESS is not unique. The same data already has been used to create an address in the integrity table
    echo curl -s -X POST -H "Content-Type: application/json" ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_JCF_BATCH_INTEGRITY_PATH} --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"batch\": \"${IMPORT_ID}\"}"
    local INTEGRITY_ID=$(curl -s -X POST -H "Content-Type: application/json" ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_JCF_BATCH_INTEGRITY_PATH} --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"batch\": \"${IMPORT_ID}\"}" | jq -r '.id')
    echo "integrity db id: ${INTEGRITY_ID}"
    # curl sendtoaddress small amount
    local INTEGRITY_PRE_TX=$(curl -s --user $rpcuser:$rpcpassword  --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"sendpretx\", \"method\": \"sendtoaddress\", \"params\": [\"${INTEGRITY_ADDRESS}\", ${SCRIPT_VERSION}, \"\", \"\"] }" -H "content-type: text/plain;" http://$komodo_node_ip:$rpcport/ | jq -r '.result')
    echo "integrity pre tx: ${INTEGRITY_PRE_TX}"
    curl -s -X PUT -H 'Content-Type: application/json' ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_JCF_BATCH_INTEGRITY_PATH}${INTEGRITY_ID}/ --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"integrity_pre_tx\": \"${INTEGRITY_PRE_TX}\" }"
}

###########################
# organization wallet = $1
# raw_json import data = $2
# batch database id = $3
###########################
function import-raw-refresco-batch-integrity-pre-process {
    echo "#### RAW REFRESCO ####"
    local WALLET=$1
    local DATA=$2 # this is raw_json TODO needs to save in db
    local IMPORT_ID=$3
    echo "Checking import id: ${IMPORT_ID}"
    _jq() {
     echo ${DATA} | base64 --decode | jq -r ${1}
    }

    _getaddress() {
      SIGNED_ITEM=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"signrawjson\", \"method\": \"signmessage\", \"params\": [\"${WALLET}\", \"${1}\"] }" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result' | base64 -w 0) # | sed 's/\=//')
      ITEM_ADDRESS=$(php ${BLOCKNOTIFY_DIR}genaddressonly.php $SIGNED_ITEM | jq -r '.address')
      echo ${ITEM_ADDRESS}
    }
    # integrity-before-processing , create blockchain-address for the import data from integration pipeline
    # blockchain-address has a database constraint for uniqueness.  will fail if exists
    # signmessage, genkomodo.php
    # update batches-api with "import-address"
    # send "pre-process" tx to "import-address"

    # no wrap base64 from https://superuser.com/a/1225139
    local SIGNED_DATA=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"signrawjson\", \"method\": \"signmessage\", \"params\": [\"${WALLET}\", \"${DATA}\"] }" -H 'content-type: text/plain;' http://127.0.0.1:$rpcport/ | jq -r '.result' | base64 -w 0) # | sed 's/\=//')
    echo "signed data: ${SIGNED_DATA}"
    local INTEGRITY_ADDRESS=$(php ${BLOCKNOTIFY_DIR}genaddressonly.php $SIGNED_DATA | jq -r '.address')
    echo "INTEGRITY_ADDRESS will be ${INTEGRITY_ADDRESS}"
    # IMPORTANT!  this next POST will fail if the INTEGRITY_ADDRESS is not unique. The same data already has been used to create an address in the integrity table
    echo curl -s -X POST -H \"Content-Type: application/json\" ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH} --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"batch\": \"${IMPORT_ID}\"}"
    local INTEGRITY_ID=$(curl -s -X POST -H "Content-Type: application/json" ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH} --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"batch\": \"${IMPORT_ID}\"}" | jq -r '.id')
    echo "integrity db id: ${INTEGRITY_ID}"
    if [ "${INTEGRITY_ID}" != "null" ] ; then
    # curl sendtoaddress small amount
    	local INTEGRITY_PRE_TX=$(curl -s --user $rpcuser:$rpcpassword  --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"sendpretx\", \"method\": \"sendtoaddress\", \"params\": [\"${INTEGRITY_ADDRESS}\", ${SCRIPT_VERSION}, \"\", \"\"] }" -H "content-type: text/plain;" http://$komodo_node_ip:$rpcport/ | jq -r '.result')
    	echo "integrity pre tx: ${INTEGRITY_PRE_TX}"
    	curl -s -X PUT -H 'Content-Type: application/json' ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH}${INTEGRITY_ID}/ --data "{\"integrity_address\": \"${INTEGRITY_ADDRESS}\", \"integrity_pre_tx\": \"${INTEGRITY_PRE_TX}\" }"

	# TODO JCF data model will use this mechanism
	# GET THE PARTS OF IMPORT DATA THAT NEED A TX SENT
	local ANFP=$(_jq '.anfp')
	local PON=$(_jq '.pon')
	local BNFP=$(_jq '.bnfp')
	local ANFP_ADDRESS=$(_getaddress ${ANFP})
	local PON_ADDRESS=$(_getaddress ${PON})
	local BNFP_ADDRESS=$(_getaddress ${BNFP})
	echo "IMPORT DATA TO SEND TO: ${ANFP} has ${ANFP_ADDRESS}  & ${PON} has ${PON_ADDRESS} & ${BNFP} has ${BNFP_ADDRESS}"
	local SMTXID=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"smbatchinputs\", \"method\": \"sendmany\", \"params\": [\"\", {\"${ANFP_ADDRESS}\":0.001,\"${PON_ADDRESS}\":0.002, \"${BNFP_ADDRESS}\": 0.003} ]} " -H 'content-type: text/plain;' http://$komodo_node_ip:$rpcport/ | jq -r '.result')
	echo "${SMTXID} is the sendmany"

    else
	echo "Cannot complete integrity tx, likely cause is RAW_JSON is empty and/or already exists which creates duplicate integrity address, not allowed by db uniqueness constraint"
	# TODO add duplicate flag to batch import, so it does not try again
    fi
}

# general flow (high level)
#############################
# check for unprocessed imports (import api)
# check for imports with address but no pre-process tx (indicates something wrong with rpc to signmessage or php address-gen)
# check for imports with address but no post-process tx (indicates incomplete import, potential rpc error)
# check for unaddressed records { certificates, facilities, country etc. }
# generate address in subprocess
# fund new wallets that need funding
# wallet maintenance (e.g. consolidate utxos, make sure threshold minimum available for smooth operation)
#############################

# TODO IMPORTANT! integrity issue if batches funded by product journey inputs more than once
# batches getting funded by certificates, locations, dates, IMPORTANT! processing twice a problem. (MYLO)
# certificates are funded wallets, processing twice not ideal, but not an integrity problem.
# batches are paper wallets, processing twice not a problem IF only for updating address data for APIs

#############################
# variables v1
# IMPORTANT! can add, but do not change names until v2 is sanctioned by vic/CI/CD team (MYLO)
#############################
BLOCKHASH=${1}
EXPLORER_1_BASE_URL=
EXPLORER_2_BASE_URL=
INSIGHT_API_GET_ADDRESS_UTXO="insight-api-komodo/addrs/XX_CHECK_ADDRESS_XX/utxo"
INSIGHT_API_BROADCAST_TX="insight-api-komodo/tx/send"
IMPORT_API_BASE_URL=
IMPORT_API_INTEGRITY_PATH=integrity/
IMPORT_API_BATH_PATH=batch/
JUICYCHAIN_API_BASE_URL=
BLOCKNOTIFY_DIR=$(env  | grep BLOCKNOTIFY_DIR | cut -d '=' -f2-)
BLOCKNOTIFY_CHAINSYNC_LIMIT=$(env  | grep BLOCKNOTIFY_CHAINSYNC_LIMIT | cut -d '=' -f2-)

# dev v1 import-api
DEV_IMPORT_API_IP=$(env  | grep IMPORT_API_IP | cut -d '=' -f2-)
DEV_IMPORT_API_PORT=$(env  | grep IMPORT_API_PORT | cut -d '=' -f2-)
DEV_IMPORT_API_BASE_URL=http://${DEV_IMPORT_API_IP}:${DEV_IMPORT_API_PORT}/
DEV_IMPORT_API_JCF_BATCH_INTEGRITY_PATH=$(env  | grep DEV_IMPORT_API_JCF_BATCH_INTEGRITY_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_JCF_BATCH_PATH=$(env  | grep DEV_IMPORT_API_JCF_BATCH_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_JCF_BATCH_REQUIRE_INTEGRITY_PATH=$(env  | grep DEV_IMPORT_API_JCF_BATCH_REQUIRE_INTEGRITY_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_JCF_BATCH_NEW_PATH=$(env  | grep DEV_IMPORT_API_BATCH_NEW_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_RAW_REFRESCO_PATH=$(env  | grep DEV_IMPORT_API_RAW_REFRESCO_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_RAW_REFRESCO_REQUIRE_INTEGRITY_PATH=$(env  | grep DEV_IMPORT_API_RAW_REFRESCO_REQUIRE_INTEGRITY_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_RAW_REFRESCO_NEW_PATH=$(env  | grep DEV_IMPORT_API_RAW_REFRESCO_NEW_PATH | cut -d '=' -f2-)
DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH=$(env  | grep DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH | cut -d '=' -f2-)

# TODO after 15 Sept
################################
# dev v1 juicychain-api
DEV_JUICYCHAIN_API_BASE_URL=http://localhost:8888/
DEV_JUICYCHAIN_API_BATCH_PATH=batch/
DEV_JUICYCHAIN_API_CERTIFICATE_PATH=certificate/
DEV_JUICYCHAIN_API_LOCATION_PATH=location/
DEV_JUICYCHAIN_API_COUNTRY_PATH=country/
DEV_JUICYCHAIN_API_BLOCKCHAIN_ADDRESS_PATH=blockchain-address/

##############################
# note, var substitution for XX_CHECK_ADDRESS_XX
# ADDRESS_TO_CHECK="MYLO"
# out="${INSIGHT_API_GET_ADDRESS_UTXO/XX_CHECK_ADDRESS_XX/${ADDRESS_TO_CHECK}}"
# echo $out
#############################

# house keeping
#############################
# get the block height this blocknotify is running,send to api/db/reporting TODO finalize these vars with vic (MYLO)
#BLOCKHEIGHT=$(curl -s --user $rpcuser:$rpcpassword --data-binary "{\"jsonrpc\": \"1.0\", \"id\":\"curltest\", \"method\": \"getblock\", \"params\": [\"${BLOCKHASH}\"] }" -H 'content-type: text/plain;' http://$komodo_node_ip:$rpcport/ | jq -r '.result.height')

################################################################################
# for JCF, JCF_BATCH are the only "BATCH" we refer to as a var in this script
# to onboard new partners, copy & replace RAW_REFRESCO section below

#############################
# batch logic - jcf data model
#############################
# receive json responses
echo "poll import-api: batch/require_integrity/ result follows:"
echo curl -s -X GET ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_JCF_BATCH_REQUIRE_INTEGRITY_PATH}
RES_DEV_IMPORT_API_JCF_BATCHES_NULL_INTEGRITY=$(curl -s -X GET ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_JCF_BATCH_REQUIRE_INTEGRITY_PATH})
# from https://stackoverflow.com/a/46955018
if jq -e . >/dev/null 2>&1 <<<"${RES_DEV_IMPORT_API_JCF_BATCHES_NULL_INTEGRITY}"; then
    echo "Parsed JSON successfully and got something other than false/null"
    echo "Start JSON response"
    echo ${RES_DEV_IMPORT_API_JCF_BATCHES_NULL_INTEGRITY}
    echo "End JSON response"
else
    echo "Failed to parse JSON, or got false/null"
fi

# DEV_IMPORT_API_JCF_BATCH_INTEGRITY_NO_POST_TX=$(curl -s -X GET ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_INTEGRITY_PATH})
# TODO batches/integrity/missing_post_tx/
# echo ${DEV_IMPORT_API_JCF_BATCH_INTEGRITY_NO_POST_TX}

# integrity-before-processing , check / create address for the import data from integration pipeline
# signmessage, genkomodo.php
# update batches-api with "import-address"
# send "pre-process" tx to "import-address"

for row in $(echo "${RES_DEV_IMPORT_API_JCF_BATCHES_NULL_INTEGRITY}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   RAW_JSON=$(_jq '.raw_json? | .raw_json' > /dev/null)
   BATCH_DB_ID=$(_jq '.id? | .id' > /dev/null)
   echo "Checking if id exists"
   if [ "${BATCH_DB_ID+x}" = "x" ] ; then
	   echo "No result, skipping...."
   else
	   import-jcf-batch-integrity-pre-process ${THIS_NODE_WALLET} ${RAW_JSON} ${BATCH_DB_ID}
   fi
done

################################################################################
# for new raw data checking, copy next ~30 lines
# replace RAW_REFRESCO with RAW_NEWCOMPANY
# make sure new vars are declared for RAW_NEWCOMPANY stuff

#############################
# batch logic - raw refresco
#############################
# receive json responses
echo "poll import-api: ${DEV_IMPORT_API_RAW_REFRESCO_REQUIRE_INTEGRITY_PATH} result follows:"
RES_DEV_IMPORT_API_RAW_REFRESCO_NULL_INTEGRITY=$(curl -s -X GET ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_RAW_REFRESCO_REQUIRE_INTEGRITY_PATH})
echo ${RES_DEV_IMPORT_API_RAW_REFRESCO_NULL_INTEGRITY}

# DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_NO_POST_TX=$(curl -s -X GET ${DEV_IMPORT_API_BASE_URL}${DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_PATH})
echo "TODO raw-refresco/integrity/missing_post_tx/"
# echo ${DEV_IMPORT_API_RAW_REFRESCO_INTEGRITY_NO_POST_TX}

# integrity-before-processing , check / create address for the import data from integration pipeline
# signmessage, genkomodo.php
# update batches-api with "import-address"
# send "pre-process" tx to "import-address"

for row in $(echo "${RES_DEV_IMPORT_API_RAW_REFRESCO_NULL_INTEGRITY}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

# TODO NOTE: if the RAW_JSON is the same as another import, during the pre-process, the address generation will be same as existing
# so it will not create a new batch tx, and always be in the list of new unprocessed imports
   # CORRECT
   RAW_JSON=$row
   # TO FORCE {} FOR TESTING
   # RAW_JSON=$(_jq '.raw_json')
   # echo $RAW_JSON | base64 --decode
   BATCH_DB_ID=$(_jq '.id')
   import-raw-refresco-batch-integrity-pre-process ${THIS_NODE_WALLET} ${RAW_JSON} ${BATCH_DB_ID}
done
###############################################################################

#
# DONT LOOK PAST THIS LINE
#

###############################################################################

# TODO for loop with jq (for each batch with with pre-process tx (not conceived properly yet) (MYLO)
# for each input for this batch, generate tx
# electrum-komodo stuff
# signmessage of input
# genkomodo.php to get wif & address
# get utxo for input to send to batch INSIGHT_API_GET_ADDRESS_UTXO
# createrawtransaction funding batch address & sending change back to this (input) address
# use wif in signmessage.py with the utxo
# broadcast via explorer INSIGHT_API_BROADCAST_TX

# integrity-after-processing
# send "post-process" tx to "import-address"
# "import-address" with pre & post process tx


#############################


############################
# cert logic

# CERTIFICATES_NEW_NO_ADDRESS=$(curl -s -X GET ${CERTIFICATES_GET_UNADDRESSED_URL})
# CERTIFICATES_NO_FUNDING_TX=$(curl -s -X GET ${CERTIFICATES_GET_NO_FUNDING_TX_URL})

# for loop with jq (for each certificate with no address do this)
# signmessage(cert_identifier)
# genkomodo.php for address
# update juicychain-api with address
# certificates need funding, rpc sendtoaddress
# update juicychain-api with funding tx (separate to address-gen update, possibly no funds to send)
