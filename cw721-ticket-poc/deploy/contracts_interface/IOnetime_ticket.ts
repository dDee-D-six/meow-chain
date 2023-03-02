import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { StdFee } from "@cosmjs/stargate";

interface Fees {
  upload: StdFee;
  init: StdFee;
  exec: StdFee;
}

interface RentPriceResponse {
  readonly price: number;
}
interface NodeInfoResponse {
  label: number[];
  token_id: String;
  node: number[];
}
interface ControllerInstance {
  readonly contractAddress: string;

  //Query functions

  //Execute functions
  mint: (
    senderAddress: string,

    token_uri: string,
    extension: any
  ) => Promise<any>;
}

interface ControllerContract {
  use: (contractAddress: string) => ControllerInstance;
}

export const IOnetime_ticket = (client: SigningCosmWasmClient, fees: Fees): ControllerContract => {
  const use = (contractAddress: string): ControllerInstance => {
    const mint = async (senderAddress: string, token_uri: string, extension: {}): Promise<any> => {
      const res = await client.execute(
        senderAddress,
        contractAddress,
        {
          mint: {
            owner: senderAddress,
            token_id: "test1",
            token_uri,
            extension,
          },
        },
        fees.exec
      );
      return res;
    };

    return {
      contractAddress,
      mint,
    };
  };
  return { use };
};
