import { calculateFee, GasPrice } from "@cosmjs/stargate";
import * as fs from "fs";
import * as _ from "lodash";

import dotenv from "dotenv";
dotenv.config();

const appArgs = process.argv[2] ?? "";
console.info(`Initialize deploy data for ${appArgs}`);
console.info(`Initializing...`);
const fileName = `./deploy_config/deploy_data_${appArgs}.json`;
const deployData = require(fileName);

const gasPrice = GasPrice.fromString(deployData.chain_config.gas_price);
const fees = {
  upload: calculateFee(5_000_000, gasPrice),
  init: calculateFee(500_000, gasPrice),
  exec: calculateFee(2_000_000, gasPrice),
};
_.set(deployData, "fees.upload", fees.upload);
_.set(deployData, "fees.init", fees.init);
_.set(deployData, "fees.exec", fees.exec);

fs.writeFileSync(fileName, JSON.stringify(deployData, null, 4));
