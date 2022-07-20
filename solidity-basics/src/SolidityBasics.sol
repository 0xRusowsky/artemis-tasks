// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// Task 1: Implement a function that takes a string as input and returns its length

contract StringLength {
    // @dev Must convert to bytes to use find out its length
    function sLength(string memory s) public pure returns (uint256) {
        return bytes(s).length;
    }
}

// Task 2: Find a way to iterate over a mapping
contract IterativeMapping {

}

// Task 3: Implement a Counter contract which should:
//   - Store the current counter number in storage.
//   - Have an increment function that can be called by EOAs, other smart contracts, and the current contract.
//   - Have a decrement function that can only be executed via an external call.
//   - Emit events loggin the executed function, and the number of the block in which the transaction was included.

contract Counter {
    uint256 public c;

    event ModifiedCounter(string executedFunction, uint256 blockNumber);

    // doesn't work, i'm still trying to figure this out haha
    modifier onlyExternalCalls() {
        require(tx.origin != address(this), "only callable by external calls!");
        _;
    }

    function incrementCount() public {
        c++;
        emit ModifiedCounter("incrementCount", block.number);
    }

    function decrementCount() public onlyExternalCalls {
        c--;
        emit ModifiedCounter("decrementCount", block.number);
    }

    // @notice To test if the modifier works properly
    function internalDecrement() public {
        decrementCount();
    }
}

// Task 4: Implement a Whitelist contract which should:
//   - Store a list of whitelisted address in Ethereum's state
//   - Have a maximum of possible whitelisted addresses that should be defined at deployment
//   - Not allow any duplicated whitelisted addresses
//   - Have a function that lets anyone add his address to the whitelist

contract Whitelist {

}
