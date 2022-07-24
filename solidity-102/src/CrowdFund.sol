// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

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
//   - After the owner withdraws the funds, campaigns should be marked either as Fully-Funded (if raised >= funding goal) or Partially-Funded (if raised < funding goal)
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
    uint256 public deadline;
    CampaignOutcome public campaignOutcome;
    bool public canceled;
    address[] donors;
    mapping(address => uint256) donatedFunds;

    constructor(
        string memory _name,
        address _owner,
        CampaignType _type,
        uint256 _goal,
        uint256 _deadline
    ) {
        require(_deadline <= 5184000, "Max length of 60 days");
        name = _name;
        owner = payable(_owner);
        campaignType = _type;
        goal = _goal;
        deadline = block.timestamp + _deadline;
    }

    /* == EVENTS ================================== */

    event NewDonation(
        uint256 indexed timestamp,
        address indexed sender,
        uint256 amount
    );
    event CampaignClosure(uint256 timestamp, uint256 valueRaised);
    event Withdraw(uint256 timestamp, address receiver, uint256 amount);

    /* == MODIFIERS ================================== */

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier liveCampaign() {
        require(block.timestamp <= deadline, "Deadline closed");
        require(!canceled, "Canceled campaign");
        require(address(this).balance - msg.value <= goal, "Goal reached");
        _;
    }

    modifier redeemableCampaign() {
        require(block.timestamp >= deadline, "Not redeemable yet");
        _;
    }

    /* == FUNCTIONS ================================== */

    fallback() external payable liveCampaign {
        if (donatedFunds[msg.sender] == 0) {
            donors.push(msg.sender);
        }
        donatedFunds[msg.sender] += msg.value;
        emit NewDonation(block.timestamp, msg.sender, msg.value);
    }

    receive() external payable liveCampaign {
        if (donatedFunds[msg.sender] == 0) {
            donors.push(msg.sender);
        }
        donatedFunds[msg.sender] += msg.value;
        emit NewDonation(block.timestamp, msg.sender, msg.value);
    }

    function withdrawFunds(address receiver)
        public
        payable
        onlyOwner
        redeemableCampaign
    {
        uint256 funds = address(this).balance;
        (bool sent, ) = receiver.call{value: funds}("");
        require(sent, "Failed to withdraw");
        emit Withdraw(block.timestamp, receiver, funds);
        campaignOutcome = (
            funds >= goal
                ? CampaignOutcome.FullyFunded
                : CampaignOutcome.PartiallyFunded
        );
    }

    function cancelCampaign() public payable onlyOwner liveCampaign {
        for (uint8 i = 0; i < donors.length; ++i) {
            if (donatedFunds[donors[i]] > 0) {
                (bool sent, ) = donors[i].call{value: donatedFunds[donors[i]]}(
                    "Campaign refund"
                );
                require(sent, "Failed to refund");
                donatedFunds[donors[i]] = 0;
            }
        }
        canceled = true;
    }
}

contract CrowdFundFactory {
    mapping(address => uint8) public userCampaigns;
    mapping(address => Campaign[]) public userCampaignContracts;

    /* == EVENTS ================================== */

    event NewCampaign(
        string campaignName,
        address campaignAddress,
        address owner,
        uint256 indexed timestamp
    );

    /* == FUNCTIONS ================================== */

    function createCampaign(
        string memory _name,
        Campaign.CampaignType _type,
        uint256 _goal,
        uint32 _deadline
    ) public {
        Campaign newCampaign = new Campaign(
            _name,
            msg.sender,
            _type,
            _goal,
            _deadline
        );
        userCampaigns[msg.sender]++;
        userCampaignContracts[msg.sender].push(newCampaign);

        emit NewCampaign(
            _name,
            address(newCampaign),
            msg.sender,
            block.timestamp
        );
    }
}
