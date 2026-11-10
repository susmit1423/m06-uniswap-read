#!/usr/bin/env bash
# Milestone 06 - read-only query of the Uniswap v3 USDC/WETH 0.30% pool on Ethereum mainnet.
# Needs: Foundry (cast), bc. No wallet, no keys, no transactions.
set -euo pipefail

: "${ETH_RPC_URL:?Set ETH_RPC_URL to an Ethereum MAINNET RPC URL}"

FACTORY=0x1F98431c8aD98523631AE4a59f267346ea31F984   # UniswapV3Factory
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48      # 6 decimals
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2      # 18 decimals
POOL=0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8      # from Uniswap's v3 deployments page
FEE=3000                                             # 0.30% tier

lower() { echo "$1" | tr 'A-F' 'a-f'; }
num()   { awk '{print $1}'; }   # strip cast's "[1.2e3]" annotation

# --- Check 1: right network ---
CHAIN=$(cast chain-id)
if [ "$CHAIN" != "1" ]; then echo "ERROR: chain id is $CHAIN, expected 1 (Ethereum mainnet)"; exit 1; fi

# Pin every read to ONE block so all values are consistent
BLOCK=$(cast block-number)
TS=$(cast block "$BLOCK" --field timestamp)

# --- Check 2: pool address really comes from the official factory ---
FROM_FACTORY=$(cast call "$FACTORY" "getPool(address,address,uint24)(address)" "$USDC" "$WETH" "$FEE" --block "$BLOCK")
if [ "$(lower "$FROM_FACTORY")" != "$(lower "$POOL")" ]; then
  echo "ERROR: factory returned $FROM_FACTORY, expected $POOL"; exit 1
fi

TOKEN0=$(cast call "$POOL" "token0()(address)" --block "$BLOCK")
TOKEN1=$(cast call "$POOL" "token1()(address)" --block "$BLOCK")
POOLFEE=$(cast call "$POOL" "fee()(uint24)" --block "$BLOCK" | num)
LIQ=$(cast call "$POOL" "liquidity()(uint128)" --block "$BLOCK" | num)

# slot0 returns 7 values, one per line
SLOT0=$(cast call "$POOL" "slot0()(uint160,int24,uint16,uint16,uint16,uint8,bool)" --block "$BLOCK")
SQRTP=$(echo "$SLOT0" | sed -n 1p | num)
TICK=$(echo "$SLOT0" | sed -n 2p | num)
FEEPROTO=$(echo "$SLOT0" | sed -n 6p | num)

# Token balances held by the pool ("reserves")
BAL_USDC=$(cast call "$USDC" "balanceOf(address)(uint256)" "$POOL" --block "$BLOCK" | num)
BAL_WETH=$(cast call "$WETH" "balanceOf(address)(uint256)" "$POOL" --block "$BLOCK" | num)

# Price of 1 WETH in USDC: token0=USDC(6dp), token1=WETH(18dp)
# USDC per WETH = 2^192 * 10^12 / sqrtPriceX96^2
PRICE=$(echo "scale=2; 2^192 * 10^12 / ($SQRTP^2)" | bc)

echo "=== Uniswap v3 USDC/WETH 0.30% pool - read-only snapshot ==="
echo "network        : Ethereum mainnet (chain id $CHAIN)"
echo "block          : $BLOCK"
echo "block time     : $TS (unix) = $(date -u -r "$TS" 2>/dev/null || date -u -d "@$TS") UTC"
echo "pool           : $POOL  (factory.getPool match: OK)"
echo "token0 / token1: $TOKEN0 / $TOKEN1"
echo "fee tier       : $POOLFEE (hundredths of a bip; 3000 = 0.30%)"
echo "sqrtPriceX96   : $SQRTP"
echo "tick           : $TICK"
echo "price          : 1 WETH = $PRICE USDC"
echo "liquidity (L)  : $LIQ"
echo "pool USDC bal  : $(cast format-units "$BAL_USDC" 6) USDC"
echo "pool WETH bal  : $(cast format-units "$BAL_WETH" 18) WETH"
echo "feeProtocol    : $FEEPROTO  (token0 part = $((FEEPROTO % 16)), token1 part = $((FEEPROTO >> 4)); 0 = off, N = 1/N of swap fee)"
