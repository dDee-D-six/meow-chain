use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use cosmwasm_std::{to_binary, Binary, CosmosMsg, StdResult, WasmMsg};
use cw721::Expiration;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    /// Name of the NFT contract
    pub name: String,
    /// Symbol of the NFT contract
    pub symbol: String,

    /// The minter is the only one who can create new NFTs.
    /// This is designed for a base NFT that is controlled by an external program
    /// or contract. You will likely replace this with custom logic in custom NFTs
    pub minter: String,

    // consumtion params
    pub invalid_to_consume: bool,
    pub consumtion_limit: u64,
    pub consumtion_count: u64,
}

/// This is like Cw721ExecuteMsg but we add a Mint command for an owner
/// to make this stand-alone. You will likely want to remove mint and
/// use other control logic in any contract that inherits this.
#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg<T> {
    /// Transfer is a base message to move a token to another account without triggering actions
    TransferNft {
        recipient: String,
        token_id: String,
    },
    /// Send is a base message to transfer a token to a contract and trigger an action
    /// on the receiving contract.
    SendNft {
        contract: String,
        token_id: String,
        msg: Binary,
    },

    Consume {
        token_id: String,
    },

    /// Allows operator to transfer / send the token from the owner's account.
    /// If expiration is set, then this allowance has a time/height limit
    Approve {
        spender: String,
        token_id: String,
        expires: Option<Expiration>,
    },
    /// Remove previously granted Approval
    Revoke {
        spender: String,
        token_id: String,
    },
    /// Allows operator to transfer / send any token from the owner's account.
    /// If expiration is set, then this allowance has a time/height limit
    ApproveAll {
        operator: String,
        expires: Option<Expiration>,
    },
    /// Remove previously granted ApproveAll permission
    RevokeAll {
        operator: String,
    },

    /// Mint a new NFT, can only be called by the contract minter
    Mint(MintMsg<T>),

    /// Burn an NFT the sender has access to
    Burn {
        token_id: String,
    },

    //Spawn
    Spawn {
        name: String,
        symbol: String,
        minter: String,
        invalid_to_consume: bool,
        consumtion_limit: u64,
        consumtion_count: u64,
    },

    /// Extension msg
    Extension {
        msg: T,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MintMsg<T> {
    /// Unique ID of the NFT
    pub token_id: String,
    /// The owner of the newly minter NFT
    pub owner: String,
    /// Universal resource identifier for this NFT
    /// Should point to a JSON file that conforms to the ERC721
    /// Metadata JSON Schema
    pub token_uri: Option<String>,
    /// Any custom extension used by this contract

    /// consumtion params
    pub consumtion_limit: u64,

    pub extension: T,
    pub(crate) invalid_to_consume: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg<Q> {
    /// Return the owner of the given token, error if token does not exist
    /// Return type: OwnerOfResponse
    OwnerOf {
        token_id: String,
        /// unset or false will filter out expired approvals, you must set to true to see them
        include_expired: Option<bool>,
    },

    ConsumtionInfo {
        token_id: String,
    },

    CheckConsumtions {},

    /// Return operator that can access all of the owner's tokens.
    /// Return type: `ApprovalResponse`
    Approval {
        token_id: String,
        spender: String,
        include_expired: Option<bool>,
    },
    /// Return approvals that a token has
    /// Return type: `ApprovalsResponse`
    Approvals {
        token_id: String,
        include_expired: Option<bool>,
    },
    /// List all operators that can access all of the owner's tokens
    /// Return type: `OperatorsResponse`
    AllOperators {
        owner: String,
        /// unset or false will filter out expired items, you must set to true to see them
        include_expired: Option<bool>,
        start_after: Option<String>,
        limit: Option<u32>,
    },
    /// Total number of tokens issued
    NumTokens {},

    /// With MetaData Extension.
    /// Returns top-level metadata about the contract: `ContractInfoResponse`
    ContractInfo {},
    /// With MetaData Extension.
    /// Returns metadata about one particular token, based on *ERC721 Metadata JSON Schema*
    /// but directly from the contract: `NftInfoResponse`
    NftInfo {
        token_id: String,
    },
    /// With MetaData Extension.
    /// Returns the result of both `NftInfo` and `OwnerOf` as one query as an optimization
    /// for clients: `AllNftInfo`
    AllNftInfo {
        token_id: String,
        /// unset or false will filter out expired approvals, you must set to true to see them
        include_expired: Option<bool>,
    },

    /// With Enumerable extension.
    /// Returns all tokens owned by the given address, [] if unset.
    /// Return type: TokensResponse.
    Tokens {
        owner: String,
        start_after: Option<String>,
        limit: Option<u32>,
    },
    /// With Enumerable extension.
    /// Requires pagination. Lists all token_ids controlled by the contract.
    /// Return type: TokensResponse.
    AllTokens {
        start_after: Option<String>,
        limit: Option<u32>,
    },

    // Return the minter
    Minter {},

    /// Extension query
    Extension {
        msg: Q,
    },
}

/// Shows who can mint these tokens
#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
pub struct MinterResponse {
    pub minter: String,
}

/// Shows Consumtion info
#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
pub struct ConsumtionInfoResponse {
    pub invalid_to_consume: bool,
    pub consumtion_limit: u64,
    pub consumtion_count: u64,
}

#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
pub struct CheckConsumtionResponse {
    pub invalid_to_consume: bool,
}

#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
#[serde(rename_all = "snake_case")]
pub enum CollectablesExecuteMsg {
    QuickMint(QuickMintMsg),
}
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct QuickMintMsg {
    pub collection_id: u64,
    pub num_to_mint: u64,
    pub owner: String,

}

impl QuickMintMsg {
    /// serializes the message
    pub fn into_binary(self) -> StdResult<Binary> {
        let msg = CollectablesExecuteMsg::QuickMint(self);
        to_binary(&msg)
    }
    /// creates a cosmos_msg sending this struct to the named contract
    pub fn into_cosmos_msg<T: Into<String>, C>(self, contract_addr: T) -> StdResult<CosmosMsg<C>>
    where
        C: Clone + std::fmt::Debug + PartialEq + JsonSchema,
    {
        let msg = self.into_binary()?;
        let execute = WasmMsg::Execute {
            contract_addr: contract_addr.into(),
            msg,
            funds: vec![],
        };
        Ok(execute.into())
    }
}
