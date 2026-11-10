# Milestone 06 — Read a Uniswap v3 pool (read-only)

Queries the Uniswap v3 **USDC/WETH 0.30%** pool on **Ethereum mainnet** at one pinned block and prints:
price, tick, liquidity, the pool's token balances, and `feeProtocol` (whether the protocol fee is on).

No wallet, no private keys, no transactions — only `eth_call` view reads.

## Setup
1. Install Foundry (`cast`): https://book.getfoundry.sh/getting-started/installation
2. Use any Ethereum **mainnet** RPC URL (Alchemy/Infura, or a public one):
   `export ETH_RPC_URL=https://ethereum-rpc.publicnode.com`
   Do not commit an RPC URL that contains your API key.

## Run
`chmod +x read_pool.sh && ./read_pool.sh`

## Inputs
| Item | Value |
|---|---|
| UniswapV3Factory | `0x1F98431c8aD98523631AE4a59f267346ea31F984` |
| Pool (USDC/WETH 0.30%) | `0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8` |
| USDC | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| WETH | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` |
| Fee tier | `3000` |

## Validation checks
- Fails if the RPC is not chain id 1 (wrong network).
- Fails if `factory.getPool(USDC, WETH, 3000)` does not return the expected pool address (wrong/fake contract).
- All reads are pinned to one block so values are consistent with each other.

## Sample output (block 26381681, 2026-11-10 03:00:47 UTC)
- price: 1 WETH = 2121.97 USDC
- tick: 199719
- feeProtocol: 102 (token0 part = 6, token1 part = 6)

## Limitations
- Trusts the RPC provider to return honest chain state.
- Price is the pool's current spot price, not a TWAP — it can be moved within a block.
