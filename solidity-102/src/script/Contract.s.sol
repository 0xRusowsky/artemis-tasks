// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {Contract} from "../Contract.sol";

contract ContractScript is Script {
    function run() public {
        vm.startBroadcast();
        new Contract();
        vm.stopBroadcast();
    }
}
