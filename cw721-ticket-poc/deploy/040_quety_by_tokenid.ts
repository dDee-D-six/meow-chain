import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";
import { ethers } from "ethers";
import { ITicket_vault } from "./contracts_interface/ITicket_vault";

// import Web3 from "web3";
import * as _ from "lodash";

import dotenv from "dotenv";
dotenv.config();

async function main(network: string) {
  try {
    //intial execute config
    const fileName = `./deploy_config/deploy_data_${network}.json`;
    const deployData = require(fileName);

    const mnemonic = process.env.MNEMONIC ?? "ticket engage below future demand dash define life charge hedgehog embody prison";
    const signer = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
      prefix: deployData.chain_config.prefix,
    });
    const [addr0, ...addrs] = await signer.getAccounts();
    const client = await SigningCosmWasmClient.connectWithSigner(
      deployData.chain_config.json_rpc,
      signer
    );

    //initialize all contract
    const controller = ITicket_vault(client, deployData.fees);

    const TICKET_VAULT = controller.use(
      deployData.contract_data.ticket_vault.contract_addr
    );


    const  res2 = await TICKET_VAULT.nftInfo("dee_01");
    console.log(res2);

  } catch (error) {
    console.error("catchError :  ", error);
  }
}

///to run this file npx ts-node {network} eg. testnet,mainnet//

// const repoRoot = process.cwd() + "/../.."; // This assumes you are in `packages/cli`
const appArgs = process.argv[2] ?? "";
console.info(`Reading deploy data for ${appArgs}`);
console.info(`Execute at ${appArgs} ...`);
main(appArgs);
