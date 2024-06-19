My minimal foundry template.

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
$ forge script script/SampleDeploy.s.sol \
        -f goerli \
        --etherscan-api-key $API_KEY_ETHERSCAN \
        --private-key $DEPLOYER_KEY \
        --broadcast --verify -vv

VERIFY

$ source .env
$ forge verify-contract \
        --chain-id 10 \
        --num-of-optimizations 200000 \
        --watch \
        --constructor-args $(cast abi-encode "constructor(address,bytes)" 0x4e6bc3964dDe538ee0b04bD14f5360d993666cC3 $(cast calldata "initialize(address)" 0x7a2a5e973B944a66eCF29CcCAfC6184f179ee1A3)) \
        --etherscan-api-key $OPTIMISM_KEY \
        --compiler-version 0.8.23+commit.f704f362 \
        0x4259557F6665eCF5907c9019a30f3Cb009c20Ae7 \
        ./src/Sample.sol:Sample \

SIMULATION

$ source .env
$ forge script script/SampleDeploy.s.sol -f goerli --private-key $DEPLOYER_KEY -vv


DEBUG

$ source .env
$ forge script script/Debug.s.sol \
        --sig 'debug(uint256, address, address, uint256, bytes)' \
        $BLOCK $FROM $TO $VALUE $CALLDATA
        -f goerli \
        -vv

-tasibii