// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// Task 1. Implement a simple Ether Wallet with the following requirements:
//   - Anyone must be able to send Eth to the wallet
//   - There must be an owner
//   - Only the owner is able to withdraw Eth
//   - Only the owner can transfer ether to other accounts
//   - Events must be emitted for all of these possible actions, logging relevant data
contract SimpleWallet {
    address payable public owner;

    event Log(string fun, address from, address to, uint256 value, bytes data);

    constructor() {
        owner = payable(msg.sender);
    }

    fallback() external payable {
        emit Log("Fallback", msg.sender, address(this), msg.value, msg.data);
    }

    receive() external payable {
        emit Log("Receive", msg.sender, address(this), msg.value, "");
    }

    function withdrawl(uint256 amount) public payable {
        require(msg.sender == owner, "Not owner");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Log("Withdrawl", address(this), msg.sender, msg.value, "");
    }

    function transfer(uint256 amount, address receiver) public payable {
        require(msg.sender == owner, "Not owner");
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Log("Transfer", address(this), msg.sender, msg.value, msg.data);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
