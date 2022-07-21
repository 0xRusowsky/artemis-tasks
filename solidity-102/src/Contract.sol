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
        (bool sent, bytes memory data) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Log("Withdrawl", address(this), msg.sender, msg.value, "");
    }

    function transfer(uint256 amount, address receiver) public payable {
        require(msg.sender == owner, "Not owner");
        (bool sent, bytes memory data) = receiver.call{value: amount}(msg.data);
        require(sent, "Failed to send Ether");

        emit Log("Transfer", address(this), msg.sender, msg.value, msg.data);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Task 2. Implement the backbone for a simple Crowdfunding platform with the following requirements:
//   - Anyone can create a campaign to acquire funding for their project
//   - Each campaign must have (at least!):
//      - A name
//      - An owner
//      - A campaign type
//      - A funding goal (in Eth)
//      - A time limit to reach it, which can't be higher than 60 days
//   - All of the above properties must be defined at campaign creation, and can't be updated.
//   - Campaigns can be of 2 types: Start-up and Charity
//   - Until the time limit of a given campaign is reached anyone can fund it by sending Eth. After time limit is reached, it can't receive any more funds.
//   - An owner of a campaign can withdraw the raised Eth only after time limit was reached.
//   - After the owner withdraws the funds, campaigns should be marked either as Fully-Funded (if raised amount is equal or greater than the funding goal) or Partially-Funded (if raised funds is lower than the funding goal)
//   - An owner must be able to cancel a campaign. If this happens that campaign can't receive any more Eth.
//   - Implement all the events you see relevant
//   - Extra: If the owner cancels a campaign, all funds must be returned to the respective donors.

contract Campaign {
    enum CampaignType {
        StartUp,
        Charity
    }

    enum CampaignOutcome {
        PartiallyFunded,
        FullyFunded
    }

    string public name;
    address payable public owner;
    CampaignType public campaignType;
    uint256 public goal;
    uint32 public deadline;
    CampaignOutcome public campaignOutcome;
    bool public canceled;

    constructor(
        string memory _name,
        CampaignType _type,
        uint256 _goal,
        uint32 _deadline
    ) {
        require(_deadline < block.timestamp + 5184000, "Max length of 60 days");
        name = _name;
        owner = payable(msg.sender);
        campaignType = _type;
        goal = _goal;
        deadline = _deadline;
    }

    /* == EVENTS ================================== */

    event NewDonation(address indexed sender, uint256 amount);
    event CampaignClosure(uint32 timestamp, uint256 valueRaised);
    event Withdrawl(address receiver, uint256 amount);

    /* == MODIFIERS ================================== */

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier liveCampaign() {
        require(
            block.timestamp < deadline &&
                address(this).balance + msg.value <= goal &&
                !canceled,
            "Campaign closed"
        );
        _;
    }

    modifier redeemableCampaign() {
        require(block.timestamp >= deadline, "Not redeemable yet");
        _;
    }

    /* == FUNCTIONS ================================== */

    fallback() external payable liveCampaign {
        emit NewDonation(msg.sender, msg.value);
    }

    receive() external payable liveCampaign {
        emit NewDonation(msg.sender, msg.value);
    }

    function withdrawlFunds(address receiver)
        public
        payable
        onlyOwner
        redeemableCampaign
    {
        uint256 funds = address(this).balance;
        (bool sent, bytes memory data) = receiver.call{value: funds}(msg.data);
        require(sent, "Failed to withdrawl Eth");
        emit Withdrawl(receiver, funds);
        campaignOutcome = (
            funds >= goal
                ? CampaignOutcome.FullyFunded
                : CampaignOutcome.PartiallyFunded
        );
    }

    function cancelCampaign() public payable onlyOwner liveCampaign {
        canceled = true;
    }
}

contract CrowdFund {
    /* == EVENTS ================================== */

    event NewCampaign(
        string campaignName,
        address campaignAddress,
        address owner
    );

    /* == FUNCTIONS ================================== */

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
