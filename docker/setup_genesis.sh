default_meow_home=meow_home
SIX_HOME=$1
if [ -z "$SIX_HOME" ]; then
    SIX_HOME=$default_meow_home
fi

## funtion setup_genesis
function setupGenesis() {
    NODE_PEER=$(jq '.app_state.genutil.gen_txs[0].body.memo' ./build/meownode0/config/genesis.json)

    ## replace NODE_PEER in config.toml to persistent_peers
    sed -i '' "s/persistent_peers = \"\"/persistent_peers = ${NODE_PEER}/g" ./build/${SIX_HOME}/config/config.toml

    ## replace minimum-gas-prices = "0ameow" to minimum-gas-prices = "1.25ameow" in app.toml
    sed -i '' "s/minimum-gas-prices = \"0ameow\"/minimum-gas-prices = \"1.25ameow\"/g" ./build/${SIX_HOME}/config/app.toml

    ## replace to enalbe api
    sed -i '' "108s/.*/enable = true/" ./build/${SIX_HOME}/config/app.toml

    ## replace to from 127.0.0.1 to 0.0.0.0
    sed -i '' "s/127.0.0.1/0.0.0.0/g" ./build/${SIX_HOME}/config/config.toml

    ## config genesis.json
    jq '.app_state.bank.params.send_enabled[0] = {"denom": "ameow","enabled": true}' ./build/${SIX_HOME}/config/genesis.json | sponge ./build/${SIX_HOME}/config/genesis.json

    ## demom metadata
    jq '.app_state.bank.denom_metadata[0] =  {"description": "The native staking token of the meow Protocol.","denom_units": [{"denom": "ameow","exponent": 0,"aliases": ["micromeow"]},{"denom": "mmeow","exponent": 3,"aliases": ["millimeow"]},{"denom": "meow","exponent": 6,"aliases": []}],"base": "ameow","display": "meow","name": "meow token","symbol": "meow"}' ./build/${SIX_HOME}/config/genesis.json | sponge ./build/${SIX_HOME}/config/genesis.json

    ## from stake to ameow
    sed -i '' "s/stake/ameow/g" ./build/${SIX_HOME}/config/genesis.json

    echo "Setup Genesis Success 🟢"

}

if [[ -e !./build/meownode0/config/genesis.json ]]; then
    echo "File does not exist 🖕"
else
    setupGenesis
fi