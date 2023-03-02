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

interface NftInfoResponse {
  /// Universal resource identifier for this NFT
  /// Should point to a JSON file that conforms to the ERC721
  /// Metadata JSON Schema
  token_uri: string;
  consumtion_count: number;
  consumtion_limit: number;
  /// You can add any custom metadata here when you extend cw721-base
  extension: any;
}

interface ControllerInstance {
  readonly contractAddress: string;

  //Query functions
  nftInfo: (token_id: string) => Promise<NftInfoResponse>;

  //Execute functions

  // /// Unique ID of the NFT
  // pub token_id: String,
  // /// The owner of the newly minter NFT
  // pub owner: String,
  // /// Universal resource identifier for this NFT
  // /// Should point to a JSON file that conforms to the ERC721
  // /// Metadata JSON Schema
  // pub token_uri: Option<String>,
  // /// Any custom extension used by this contract
  // pub extension: T,
  mint: (
    senderAddress: string,
    token_id: string,
    token_uri: string,
    consumtion_limit: number,
    extension: any
  ) => Promise<any>;

  consume: (senderAddress: string, token_id: string) => Promise<any>;
}

interface ControllerContract {
  use: (contractAddress: string) => ControllerInstance;
}

export const ITicket_vault = (client: SigningCosmWasmClient, fees: Fees): ControllerContract => {
  const use = (contractAddress: string): ControllerInstance => {
    const mint = async (
      senderAddress: string,
      token_id: string,
      token_uri: string,
      consumtion_limit: number,
      extension: {}

      //   name: string,
      //   owner: string,
      //   duration: number,
      //   secret: string,
      //   resolver: string,
      //   address: string
    ): Promise<any> => {
      const res = await client.execute(
        senderAddress,
        contractAddress,
        {
          mint: {
            owner: senderAddress,
            token_id: token_id,
            token_uri: token_uri,
            consumtion_limit: consumtion_limit,
            extension: extension,
          },
        },
        "auto" // fee
      );
      return res;
    };
    const consume = async (senderAddress: string, token_id: string): Promise<any> => {
      const res = await client.execute(
        senderAddress,
        contractAddress,
        {
          consume: {
            token_id: token_id,
          },
        },
        fees.exec
      );
      return res;
    };
    const nftInfo = async (token_id: string): Promise<NftInfoResponse> => {
      return await client.queryContractSmart(contractAddress, {
        nft_info: { token_id },
      });
    };

    return {
      contractAddress,
      mint,
      nftInfo,
      consume,
    };
  };
  return { use };
};
