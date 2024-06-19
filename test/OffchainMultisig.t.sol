// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { SigUtils } from "./utils/SigUtils.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { OffchainMultisig, IOffchainMultisig } from "../src/OffchainMultisig.sol";

contract OffchainMultisigTest is Test {
    MockERC20 internal mockToken;
    OffchainMultisig internal multisig;
    SigUtils internal sigUtils;

    uint256 internal owner1PrivateKey;
    uint256 internal owner2PrivateKey;

    address internal owner1;
    address internal owner2;
    address internal recipient;

    function setUp() public {
        owner1PrivateKey = 0xA11CE;
        owner2PrivateKey = 0xB0B;
        owner1 = vm.addr(owner1PrivateKey);
        owner2 = vm.addr(owner2PrivateKey);

        recipient = 0xB18922995ddE6C185430EfC9DCb79ba86D888Dba;

        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        mockToken = new MockERC20();
        multisig = new OffchainMultisig(owners, 2);
        sigUtils = new SigUtils(multisig.DOMAIN_SEPARATOR());

        vm.deal(address(multisig), 1e18);
        mockToken.mint(address(multisig), 1e18);
    }

    function _signTransferERC20(uint256 ownerPrivateKey_) internal view returns (bytes memory) {
        SigUtils.Transaction memory transaction = SigUtils.Transaction({
            destination: address(mockToken),
            value: 0,
            data: abi.encodeWithSignature("transfer(address,uint256)", recipient, 1e18)
        });

        bytes32 digest = sigUtils.getTypedDataHash(transaction);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey_, digest);

        console2.log("Owner ", vm.addr(ownerPrivateKey_), " signed transfer erc20");

        return abi.encodePacked(r, s, v);
    }

    function _signTransferNatives(uint256 ownerPrivateKey_) internal view returns (bytes memory) {
        SigUtils.Transaction memory transaction =
            SigUtils.Transaction({ destination: recipient, value: 1e18, data: "" });

        bytes32 digest = sigUtils.getTypedDataHash(transaction);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey_, digest);

        console2.log("Owner ", vm.addr(ownerPrivateKey_), " signed transfer native");

        return abi.encodePacked(r, s, v);
    }

    function testConcrete_executeTransaction_transferERC20() public {
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signTransferERC20(owner1PrivateKey);
        signatures[1] = _signTransferERC20(owner2PrivateKey);

        IOffchainMultisig.Transaction memory txn = IOffchainMultisig.Transaction({
            destination: address(mockToken),
            value: 0,
            data: abi.encodeCall(mockToken.transfer, (recipient, 1e18))
        });

        vm.expectEmit();
        emit IOffchainMultisig.Execution(
            1, address(mockToken), 0, abi.encodeWithSignature("transfer(address,uint256)", recipient, 1e18)
        );
        multisig.executeTransaction(1, txn, signatures);
    }

    function testConcrete_executeTransaction_transferNative() public {
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signTransferNatives(owner1PrivateKey);
        signatures[1] = _signTransferNatives(owner2PrivateKey);

        IOffchainMultisig.Transaction memory txn =
            IOffchainMultisig.Transaction({ destination: recipient, value: 1e18, data: "" });

        vm.expectEmit();
        emit IOffchainMultisig.Execution(2, recipient, 1e18, "");
        multisig.executeTransaction(2, txn, signatures);
    }
}
