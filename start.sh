#!/bin/bash
set -u
set -e

NETWORK_ID=$(cat genesis.json | grep chainId | awk -F " " '{print $2}' | awk -F "," '{print $1}')
CONSTELLATION_DATA_DIR="$DATA_DIR/constellation"

cp permissioned-nodes.json $DATA_DIR/static-nodes.json &&
cp permissioned-nodes.json $DATA_DIR/ &&
echo "Constellation Public Key: $(cat keys/node.pub)"

if [ $NETWORK_ID -eq 1 ]
then
    echo "Quorum should not be run with a chainId of 1 (Ethereum mainnet)"
    echo "please set the chainId in the genensis.json to another value "
    echo "1337 is the recommend ChainId for Geth private clients."
fi

if [ -d "data/keystore" ]; then
    # Will enter here if $DIRECTORY exists, even if it contains spaces
    echo "Directory exists, Skipping initialization"
else
    echo "Initializing"
    ./initialization.sh
fi

sleep 1

mkdir -p $LOG_DIR
echo "[*] Starting Constellation nodes"
./constellation-start.sh

echo "Waiting for constellation to start"
sleep 2
echo "$(cat $DATA_DIR/geth/nodekey)"

echo "[*] Starting Ethereum nodes"
WEBSOCKET_ARGS="--ws --wsaddr 0.0.0.0 --wsport $WS_PORT"
OTHER_ARGS=""
if [[ "${UNLOCK:+isset}" == "isset" ]]; then
    OTHER_ARGS="--unlock $UNLOCK --password passwords.txt"
fi
if [ "$CONSENSUS" = "raft" ]; then
  echo "Consensus algorithm: RAFT"
  ARGS="--raft --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum --emitcheckpoints --cache=$CACHE"
  PRIVATE_CONFIG=$CONSTELLATION_DATA_DIR/tm.ipc nohup geth --datadir $DATA_DIR $ARGS $WEBSOCKET_ARGS --wsorigins "*" --rpcport $RPC_PORT --permissioned --raftport $RAFT_PORT --port $GETH_PORT $OTHER_ARGS 2>>$LOG_DIR/quorum.log
elif [ "$CONSENSUS" = "istanbul" ]; then
  echo "Consensus algorithm: Istanbul"
  ARGS="--nodiscover --istanbul.blockperiod $ISTANBUL_BLOCKPERIOD --networkid $NETWORK_ID --syncmode full --mine --minerthreads $ISTANBUL_MINERTHREADS --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --cache=$CACHE"
  PRIVATE_CONFIG=$CONSTELLATION_DATA_DIR/tm.ipc nohup geth --datadir $DATA_DIR $ARGS $WEBSOCKET_ARGS --rpcport $RPC_PORT --port $GETH_PORT $OTHER_ARGS 2>>$LOG_DIR/quorum.log
fi

echo "All node configured. Attaching to geth"
