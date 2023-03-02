import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";
import { calculateFee, GasPrice } from "@cosmjs/stargate";
import * as _ from "lodash";
import * as fs from "fs";

import dotenv from "dotenv";
dotenv.config();

async function main(network: string) {
  try {
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

    const registy_msg = {
      name:"Test NFT",
      symbol:"-D-",
      minter:"6x1rsy9ksdvry53w9lvcwylcydj8l3hc5luc5dv7v",
      invalid_to_consume:false,
      consumtion_limit:0,
      consumtion_count:0,
    };

    const ticket_vault_res = await client.instantiate(
      addr0.address,
      deployData.contract_data.ticket_vault.codeId,
      registy_msg,
      "ticket_vault",
      deployData.fees.init,
      { admin: addr0.address }
    );

    _.set(
      deployData,
      "contract_data.ticket_vault.contract_addr",
      ticket_vault_res.contractAddress
    );

    fs.writeFileSync(fileName, JSON.stringify(deployData, null, 4));
  } catch (error) {
    console.error("catchError :  ", error);
  }
}

///to run this file npx ts-node {network} eg. testnet,mainnet//

// const repoRoot = process.cwd() + "/../.."; // This assumes you are in `packages/cli`
const appArgs = process.argv[2] ?? "";
console.info(`Reading deploy data for ${appArgs}`);
console.info(`Instantiate at ${appArgs} ...`);
main(appArgs);
