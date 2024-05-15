// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint256 entranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinator
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // 1. Create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator
            );
        }

        vm.startBroadcast();
        Raffle raffle;
        raffle = new Raffle(
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinator
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
