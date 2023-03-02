import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";
import { calculateFee, GasPrice } from "@cosmjs/stargate";
import * as _ from "lodash";
import * as fs from "fs";

import dotenv from "dotenv";
dotenv.config();

const main = async(paths: string[], network: string) => {
  console.log("fuck")
  try {
    //setup chain config
    const fileName = `./deploy_config/deploy_data_${network}.json`;
    const deployData = require(fileName);
    
    const mnemonic = "code code code code code"
    const signer = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
      prefix: deployData.chain_config.prefix,
    });
    const [addr0, ...addrs] = await signer.getAccounts();
    const client = await SigningCosmWasmClient.connectWithSigner(
      deployData.chain_config.json_rpc,
      signer
    );

    // Upload contract
    for (let i = 0; i < paths.length; i++) {
      console.info(`Deploying ${paths[i].toUpperCase()} contract...`);
      const wasm = fs.readFileSync(`../artifacts/${paths[i]}.wasm`);
      const uploadReceipt = await client.upload(
        addr0.address,
        wasm,
        deployData.fees.upload,
        paths[i]
      );
      console.log("smart contract codeId is : ", uploadReceipt.codeId);
      
      _.set(
        deployData,
        `contract_data.${paths[i]}.codeId`,
        uploadReceipt.codeId
      );
    }
    console.log("deployData ",deployData)
    fs.writeFileSync(fileName, JSON.stringify(deployData, null, 1));
  } catch (error) {
    console.error("catchError :  ", error);
  }
}
const deployPaths = ["ticket_vault"];
const appArgs = process.argv[2] ?? "";
console.info(`Reading deploy data for ${appArgs}`);
main(deployPaths, appArgs);
