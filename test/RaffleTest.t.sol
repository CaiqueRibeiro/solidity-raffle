// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2_5Mock.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    error InvalidRequest();

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 subscriptionId;
    bytes32 gasLane; // keyHash
    uint256 interval;
    uint256 entranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinator;

    address public PLAYER = makeAddr("player");
    uint public constant STARTING_USER_BALANCE = 10 ether;

    event EnteredRaffle(address indexed user);

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();

        (raffle, helperConfig) = deployRaffle.run();
        (
            subscriptionId,
            gasLane,
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinator,

        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // sets the block.timestamp of test network
        vm.roll(block.number + 1); // sets the block.number of test network
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 currentState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                currentState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs(); // record all logs from contract events
        raffle.performUpkeep(""); // will emit RequestedRaffleWinner
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestedId = entries[1].topics[1]; // entries are the log arrays. RequestedRaffleWinner is the second event emited

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestedId) > 0);
        assert(uint256(raffleState) == 1);
    }

    // Fuzz testing. Foundry will automatically generate the random numbers and call it multiple times
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed skipFork {
        vm.expectRevert(InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFullfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEnteredAndTimePassed
    {
        uint256 additionalEntrants = 5; // 5 more players to join raffle
        uint256 initialIndex = 1; // index starts in 0, but as we have already one player, we need to start in 1

        for (
            uint256 i = initialIndex;
            i < initialIndex + additionalEntrants;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE); // creates a new player with 10 ether (vm.prank + vm.deal)
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.recordLogs();
        raffle.performUpkeep(""); // will call VRF requestRandomWords. Will work because of modifier raffleEnteredAndTimePassed
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // RequestedRaffleWinner event

        uint256 previousTimestamp = raffle.getLastTimeStamp();

        // pretend to be chainlink vrf and call fulfillRandomWords from Raffle contract
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(uint256(raffle.getRaffleState()) == 0); // state should be reset to OPEN
        assert(raffle.getRecentWinner() != address(0)); // winner should be set
        assert(raffle.getNumberOfPlayers() == 0); // players should be reset
        assert(raffle.getLastTimeStamp() > previousTimestamp); // timestamp should be updated
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE + prize - entranceFee
        ); // winner should have received the money
    }
}
