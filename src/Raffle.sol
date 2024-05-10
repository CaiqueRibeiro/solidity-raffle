// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Raffle - A lotery contract
 * @author Caique Ribeiro Rodrigues
 * @notice This contract is for creating a simple raflle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    error Raffle__NotEnoughEth();
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimestamp;

    event EnteredRaffle(address indexed user);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {}

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
