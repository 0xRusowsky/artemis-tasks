// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {StringLength, Counter} from "../SolidityBasics.sol";

contract ContractScript is Script {
    function run() public {
        vm.startBroadcast();
        //new StringLength();
        new Counter();
        vm.stopBroadcast();
    }
}
