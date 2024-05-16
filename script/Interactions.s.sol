// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function run() external returns (uint256) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , address vrfCoordinator, ) = helperConfig
            .activeNetworkConfig();
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

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 subscriptionId,
            ,
            ,
            ,
            ,
            address vrfCoordinator,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address link
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID:", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
}
