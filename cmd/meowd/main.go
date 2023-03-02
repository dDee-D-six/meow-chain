package main

import (
	"os"

	"github.com/cosmos/cosmos-sdk/server"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/thesixnetwork/meow/app"
	"github.com/thesixnetwork/meow/cmd/meowd/cmd"
)

func main() {
	app.SetConfig()

	rootCmd, _ := cmd.NewRootCmd()
	rootCmd.AddCommand(
		cmd.AddGenesisWasmMsgCmd(app.DefaultNodeHome),
	)

	if err := svrcmd.Execute(rootCmd, app.DefaultNodeHome); err != nil {
		switch e := err.(type) {
		case server.ErrorCode:
			os.Exit(e.Code)

		default:
			os.Exit(1)
		}
	}
}
