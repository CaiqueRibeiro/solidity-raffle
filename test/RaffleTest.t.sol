// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle raffle;

    function setup() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        raffle = deployRaffle.run();
    }
}
