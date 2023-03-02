package app

import (
	"github.com/cosmos/cosmos-sdk/simapp/params"
	evmenc "github.com/evmos/ethermint/encoding"
)

// MakeEncodingConfig creates the EncodingConfig for the application.
func MakeEncodingConfig() params.EncodingConfig {
	return evmenc.MakeConfig(ModuleBasics)
}
