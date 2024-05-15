// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function run() external returns (uint256) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , address vrfCoordinator) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordination
    ) public returns (uint256) {
        console.log("Creating subscription on ChainId", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordination)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscriptionId is", subId);
        console.log("Please update subscriptionId in HelperConfig.sol");
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 subscriptionId, , , , , address vrfCoordinator) = helperConfig
            .activeNetworkConfig();
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
