export DAEMON_HOME=./opt/build/meow_home
rm -rf $DAEMON_HOME/data
rm -rf $DAEMON_HOME/wasm
rm $DAEMON_HOME/config/addrbook.json
mkdir $DAEMON_HOME/data/
touch $DAEMON_HOME/data/priv_validator_state.json
echo '{"height": "0", "round": 0,"step": 0}' > $DAEMON_HOME/data/priv_validator_state.json