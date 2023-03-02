KEY="mykey"
KEY2="mykey2"
CHAINID="meow_6666-1"
MONIKER="mynode"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
SIX_HOME=~/.meow
ALICE_MNEMONIC="history perfect across group seek acoustic delay captain sauce audit carpet tattoo exhaust green there giant cluster want pond bulk close screen scissors remind"
BOB_MNEMONIC="limb sister humor wisdom elephant weasel beyond must any desert glance stem reform soccer include chest chef clerk call popular display nerve priority venture"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Reinstall daemon
rm -rf ~/.meow*
make install

# Set client config
meowd config keyring-backend $KEYRING
meowd config chain-id $CHAINID

# if $KEY exists it should be deleted
echo $ALICE_MNEMONIC | meowd keys add $KEY --recover --home ${SIX_HOME} --keyring-backend $KEYRING --algo $KEYALGO
echo $BOB_MNEMONIC | meowd keys add $KEY2 --recover --home ${SIX_HOME} --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for meow (Moniker can be anything, chain-id must be an integer)
meowd init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to ameow
cat $HOME/.meow/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="ameow"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json
cat $HOME/.meow/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="ameow"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json
cat $HOME/.meow/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="ameow"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json
cat $HOME/.meow/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="ameow"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json
cat $HOME/.meow/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="ameow"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json

# Change voting params so that submitted proposals pass immediately for testing
cat $HOME/.meow/config/genesis.json| jq '.app_state.gov.voting_params.voting_period="30s"' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json


# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.meow/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.meow/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.meow/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.meow/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.meow/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.meow/config/config.toml
  fi
fi

# Allocate genesis accounts (cosmos formatted addresses)
meowd add-genesis-account $KEY 964723926400000000000000000ameow --keyring-backend $KEYRING
meowd add-genesis-account $KEY2 35276073600000000000000000ameow --keyring-backend $KEYRING
                                 
# Update total supply with claim values
#validators_supply=$(cat $HOME/.meow/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["amount"]')
# Bc is required to add this big numbers
# total_supply=$(bc <<< "$amount_to_claim+$validators_supply")
total_supply=1000000000000000000000000000
cat $HOME/.meow/config/genesis.json | jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' > $HOME/.meow/config/tmp_genesis.json && mv $HOME/.meow/config/tmp_genesis.json $HOME/.meow/config/genesis.json

echo $KEYRING
echo $KEY
# Sign genesis transaction
meowd gentx $KEY2 100000000000000000000000ameow --keyring-backend $KEYRING --chain-id $CHAINID
#meowd gentx $KEY2 1000000000000000000000ameow --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
meowd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
meowd validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
meowd start --pruning=nothing --trace --log_level info --minimum-gas-prices=0.0001ameow --json-rpc.api eth,txpool,personal,net,debug,web3 --rpc.laddr "tcp://0.0.0.0:26657" --api.enable true

