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
    address[] internal keys;
    mapping(address => uint256) public balances;
    mapping(address => bool) public added;

    function addAddress(uint256 _value) public {
        if (!added[msg.sender]) {
            balances[msg.sender] = _value;
            added[msg.sender] = true;
            keys.push(msg.sender);
        } else {
            balances[msg.sender] = _value;
        }
    }

    function getAddress(uint8 _i) public view returns (address, uint256) {
        return (keys[_i], balances[keys[_i]]);
    }
}

// Task 3: Implement a Counter contract which should:
//   - Store the current counter number in storage.
//   - Have an increment function that can be called by EOAs, other smart contracts, and the current contract.
//   - Have a decrement function that can only be executed via an external call.
//   - Emit events loggin the executed function, and the number of the block in which the transaction was included.

contract Counter {
    uint256 public c;

    event ModifiedCounter(string executedFunction, uint256 blockNumber);

    function incrementCount() public {
        c++;
        emit ModifiedCounter("incrementCount", block.number);
    }

    function decrementCount() external {
        c--;
        emit ModifiedCounter("decrementCount", block.number);
    }
}

// Task 4: Implement a Whitelist contract which should:
//   - Store a list of whitelisted address in Ethereum's state
//   - Have a maximum of possible whitelisted addresses that should be defined at deployment
//   - Not allow any duplicated whitelisted addresses
//   - Have a function that lets anyone add his address to the whitelist

contract Whitelist {
    uint8 public maxAddresses;
    uint8 internal numAddresses;
    mapping(address => bool) public wl;

    constructor(uint8 _maxAddresses) {
        maxAddresses = _maxAddresses;
    }

    function addAddress() public {
        require(!wl[msg.sender], "Already whitelisted!");
        require(numAddresses < maxAddresses, "Max WL reached");
        wl[msg.sender] = true;
        numAddresses++;
    }
}
