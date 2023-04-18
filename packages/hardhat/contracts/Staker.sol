// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;
    bool private openForWithdraw = false;
    // events
    event Stake(address indexed player, uint256 value);
    event Received(address, uint);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }
    receive() external payable {
        stake();
        emit Received(msg.sender, msg.value);
    }
    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public {
        require(block.timestamp > deadline, "Deadline not passed!");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
        require(openForWithdraw, "Withdraw is not open yet!");
        (bool success, ) = address(msg.sender).call{
            value: balances[msg.sender]
        }("");
        console.log(success, msg.sender, balances[msg.sender]);
        if (success) {
            balances[msg.sender] = 0;
        }
        require(success, "Withdraw Failed!");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return (deadline - block.timestamp);
    }

    // Add the `receive()` special function that receives eth and calls stake()
}
