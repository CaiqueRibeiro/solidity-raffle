// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Raffle - A lotery contract
 * @author Caique Ribeiro Rodrigues
 * @notice This contract is for creating a simple raflle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
