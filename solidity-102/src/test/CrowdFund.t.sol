// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Campaign, CrowdFundFactory} from "../CrowdFund.sol";

contract BaseSetup is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    address public alice;
    address public bob;
    address public charlie;
    address[] public owners;

    CrowdFundFactory public crowdFund;

    function setUp() public virtual {
        utils = new Utilities();
        users = utils.createUsers(3);

        alice = users[0];
        bob = users[1];
        charlie = users[2];
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");

        crowdFund = new CrowdFundFactory();
    }
}

contract WhenDealingWithCampaigns is BaseSetup {
    function setUp() public virtual override {
        BaseSetup.setUp();
        console.log("When dealing with campaigns");
    }

    function createCampaign(
        address _signer,
        string memory _name,
        Campaign.CampaignType _type,
        uint256 _goal,
        uint32 _deadline
    ) public {
        vm.prank(_signer);
        crowdFund.createCampaign(_name, _type, _goal, _deadline);
        console.log("... New campaign created");
    }

    function getCampaign(address _campaignOwner, uint8 _campaignNumber)
        public
        view
        returns (Campaign)
    {
        return crowdFund.userCampaignContracts(_campaignOwner, _campaignNumber);
    }

    function donateFunds(
        Campaign _campaign,
        address _signer,
        uint256 _funds
    ) public {
        vm.prank(_signer);
        (bool sent, ) = address(_campaign).call{value: _funds}("");
        require(sent, "Failed to send Ether");
        console.log("... Funds donated");
    }

    function endCampaign(Campaign _campaign, address _signer) public {
        vm.prank(_signer);
        _campaign.withdrawFunds(_signer);
        console.log("... Campaign closed");
    }

    function cancelCampaign(Campaign _campaign, address _signer) public {
        vm.prank(_signer);
        _campaign.cancelCampaign();
        console.log("... Campaign canceled");
    }
}

contract WhenCampaignsWorkAsIntended is WhenDealingWithCampaigns {
    function setUp() public override {
        WhenDealingWithCampaigns.setUp();
        console.log("When campaigns work as intended");
    }

    function testFullyFilledCampaigns() public {
        createCampaign(
            alice, //owner
            "Alice's Campaign #1", //name
            Campaign.CampaignType(0), //type
            1 ether, //goal
            3600 * 24 * 30 //deadline
        );
        createCampaign(
            alice,
            "Alice's Campaign #2",
            Campaign.CampaignType(1),
            3 ether,
            3600 * 24 * 40
        );
        createCampaign(
            bob,
            "Bob's Campaign #1",
            Campaign.CampaignType(1),
            2 ether,
            3600 * 24 * 60
        );
        Campaign aliceC0 = getCampaign(alice, 0);
        Campaign aliceC1 = getCampaign(alice, 1);
        Campaign bobC0 = getCampaign(bob, 0);

        donateFunds(aliceC0, bob, 0.6 ether);
        donateFunds(aliceC0, bob, 0.6 ether);
        donateFunds(aliceC1, bob, 1 ether);
        donateFunds(bobC0, alice, 1 ether);
        donateFunds(aliceC1, charlie, 2 ether);
        donateFunds(bobC0, charlie, 1 ether);

        vm.warp(aliceC0.deadline() + 1);
        endCampaign(aliceC0, alice);
        assert(aliceC0.campaignOutcome() == Campaign.CampaignOutcome(1));
        vm.warp(aliceC1.deadline() + 1);
        endCampaign(aliceC1, alice);
        assert(aliceC1.campaignOutcome() == Campaign.CampaignOutcome(1));
        vm.warp(bobC0.deadline() + 1);
        endCampaign(bobC0, bob);
        assert(bobC0.campaignOutcome() == Campaign.CampaignOutcome(1));
    }

    function testPartiallyFilledCampaign() public {
        createCampaign(
            alice, //owner
            "Alice's Campaign #1", //name
            Campaign.CampaignType(0), //type
            1 ether, //goal
            3600 * 24 * 30 //deadline
        );
        Campaign aliceC0 = getCampaign(alice, 0);

        donateFunds(aliceC0, bob, 0.6 ether);

        vm.warp(aliceC0.deadline() + 1);
        endCampaign(aliceC0, alice);
        assert(aliceC0.campaignOutcome() == Campaign.CampaignOutcome(0));
    }

    function testCanceledCampaign() public {
        createCampaign(
            alice, //owner
            "Alice's Campaign #1", //name
            Campaign.CampaignType(0), //type
            1 ether, //goal
            3600 * 24 * 30 //deadline
        );
        Campaign aliceC0 = getCampaign(alice, 0);

        uint256 bobBalance = bob.balance;
        console.log("bob blance before:");
        console.log(bob.balance / 1 ether);
        donateFunds(aliceC0, bob, 0.6 ether);
        assert(bobBalance == bob.balance + 0.6 ether);
        cancelCampaign(aliceC0, alice);
        console.log("bob blance after:");
        console.log(bob.balance / 1 ether);
        assert(bobBalance == bob.balance);

        assert(aliceC0.canceled());
    }
}
