default_meow_home=meow_home
default_docker_tag="latest"
node_homes=(
    meownode0
    meownode1
    meownode2
    meownode3
);
validator_keys=(
    val1
    val2
    val3
    val4
);

function setUpGenesis(){
       ## config genesis.json
    jq '.app_state.bank.params.send_enabled[0] = {"denom": "ameow","enabled": true}' ./build/meownode0/config/genesis.json | sponge ./build/meownode0/config/genesis.json

    ## demom metadata
    jq '.app_state.bank.denom_metadata[0] =  {"description": "The native staking token of the meow Protocol.","denom_units": [{"denom": "ameow","exponent": 0,"aliases": ["micromeow"]},{"denom": "mmeow","exponent": 3,"aliases": ["millimeow"]},{"denom": "meow","exponent": 6,"aliases": []}],"base": "ameow","display": "meow","name": "meow token","symbol": "meow"}'  ./build/meownode0/config/genesis.json | sponge ./build/meownode0/config/genesis.json

    ## from stake to ameow
    sed -i '' "s/stake/ameow/g" ./build/meownode0/config/genesis.json

       ## config genesis.json
    jq '.app_state.bank.params.send_enabled[0] = {"denom": "ameow","enabled": true}' ./build/${SIX_HOME}/config/genesis.json | sponge ./build/${SIX_HOME}/config/genesis.json

}

function setUpConfig() {
    echo "#######################################"
    echo "Setup ${SIX_HOME} genesis..."

    if [[ ${SIX_HOME} == "meownode0" ]]; then
        echo "meownode0"
        NODE_PEER=$(jq '.app_state.genutil.gen_txs[0].body.memo' ./build/meownode1/config/genesis.json)
        sed -i '' "s/persistent_peers = \"\"/persistent_peers = ${NODE_PEER}/g" ./build/${SIX_HOME}/config/config.toml
        ## setup genesis of node0
        setUpGenesis
    else
        NODE_PEER=$(jq '.app_state.genutil.gen_txs[0].body.memo' ./build/meownode0/config/genesis.json)
        ## replace NODE_PEER in config.toml to persistent_peers
        sed -i '' "s/persistent_peers = \"\"/persistent_peers = ${NODE_PEER}/g" ./build/${SIX_HOME}/config/config.toml
            ## replace genesis of node0 to all node
        cp ./build/meownode0/config/genesis.json ./build/${SIX_HOME}/config/genesis.json
    fi
    ## replace to enalbe api
    sed -i '' "108s/.*/enable = true/" ./build/${SIX_HOME}/config/app.toml
    ## replace to from 127.0.0.1 to 0.0.0.0
    sed -i '' "s/127.0.0.1/0.0.0.0/g" ./build/${SIX_HOME}/config/config.toml

    echo "Setup Genesis Success 🟢"

}

echo "#############################################"
echo "## 1. Build Docker Image                   ##"
echo "## 2. Docker Compose init chain            ##"
echo "## 3. Start chain validator                ##"
echo "## 4. Stop chain validator                 ##"
echo "## 5. Config Genesis                       ##"
echo "## 6. Reset chain validator                ##"
echo "## 7. Staking validator                    ##"
echo "## 8. Query validator                      ##"
echo "## 9. Query EVM Address                    ##"
echo "#############################################"

read -p "Enter your choice: " choice
case $choice in
    1)
        echo "Building Docker Image"
        read -p "Enter Docker Tag: " docker_tag
        if [ -z "$docker_tag" ]; then
            docker_tag=$default_docker_tag
        fi
        docker build . -t meow/node:${docker_tag}
        ;;
    2)
        echo "Run init Chain validator"
        export COMMAND="init"
        docker compose -f ./docker-compose.yml up
        ;;
    3)
        echo "Running Docker Container in Interactive Mode"
        export COMMAND="start_chain"
        docker compose -f ./docker-compose.yml up -d
        ;;
    4)
        echo "Stop Docker Container"
        export COMMAND="start_chain"
        docker compose -f ./docker-compose.yml down
        ;;
    5) 
        echo "Config Genesis"
        for home in ${node_homes[@]}
        do  
            (
            export SIX_HOME=${home}
            if [[ -e !./build/meownode0/config/genesis.json ]]; then
                echo "File does not exist 🖕"
            else
                setUpConfig
            fi 
            )|| exit 1
        done
        ;;
    6) 
        echo "Reset Docker Container"
        for home in ${node_homes[@]}
        do
            echo "#######################################"
            echo "Starting ${home} reset..."

            ( export DAEMON_HOME=./build/${home}
            rm -rf $DAEMON_HOME/data
            rm -rf $DAEMON_HOME/wasm
            rm $DAEMON_HOME/config/addrbook.json
            mkdir $DAEMON_HOME/data/
            touch $DAEMON_HOME/data/priv_validator_state.json
            echo '{"height": "0", "round": 0,"step": 0}' > $DAEMON_HOME/data/priv_validator_state.json

            echo "Reset ${home} Success 🟢"
            )|| exit 1
        done
        ;;
    7)
        echo "Staking Docker Container"
        i=1
        amount=100000001
        # i=0
        # for val in ${validator_keys[@]}
        for val in ${validator_keys[@]:1:3}
        do
            echo "#######################################"
            ( 
            echo "Creating validators ${val}"
            echo ${node_homes[i]}
            export DAEMON_HOME=./build/${node_homes[i]}
            # meowd tendermint show-validator --home ./build/${node_homes[i]}
            meowd tx staking create-validator --amount="${amount}ameow" --from ${val} --moniker ${node_homes[i]} \
                --pubkey $(meowd tendermint show-validator --home ./build/${node_homes[i]}) --home build/${node_homes[i]} \
                --keyring-backend test --commission-rate 0.1 --commission-max-rate 0.5 --commission-max-change-rate 0.1 \
                --min-self-delegation 1000000 --node http://0.0.0.0:26662 --chain-id meow_666-1 -y
            echo "Config Genesis at ${home} Success 🟢"
            ) || exit 1
            i=$((i+1))
            amount=$((amount+1))
        done
        ;;
    8)
        echo "Query Validator set"
        meowd q tendermint-validator-set --home ./build/meownode0
        ;;
    9)
        echo "Query EVM Address"
        read -p "Enter your keys name: " key
        meowd debug addr $(meowd keys show -a ${key} --home ./build/meownode0 --keyring-backend test) 
        ;;
    *)
        echo "Invalid Choice"
        ;;
esac