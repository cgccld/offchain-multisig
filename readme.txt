Off-chain Multisig

INSTALLATION

$ forge install


COMPILATION

$ forge fmt
$ forge clean
$ forge build


TESTING

$ forge test


DEPLOYMENT

$ source .env
$ forge script script/Deploy.s.sol -f tbsc --etherscan-api-key $BSCSCAN_KEY --private-key $DEPLOYER_KEY --gas-price $(cast gas-price --rpc-url $RPC_URL_TBSC) --broadcast --verify -vv

VERIFY

$ source .env
$ forge verify-contract \
        --chain-id 97 \
        --num-of-optimizations 200000 \
        --watch \
        --constructor-args "" \
        --etherscan-api-key $BSCSCAN_KEY \
        0x4259557F6665eCF5907c9019a30f3Cb009c20Ae7 \
        ./src/OffchainMultisig.sol:OffchainMultisig \

SIMULATION

$ source .env
$ forge script script/Deploy.s.sol -f tbsc --private-key $DEPLOYER_KEY -vv


DEBUG

$ source .env
$ forge script script/Debug.s.sol \
        --sig 'debug(uint256, address, address, uint256, bytes)' \
        $BLOCK $FROM $TO $VALUE $CALLDATA
        -f tbsc \
        -vv

-tasibii