// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./Lesson_12_ILogger.sol";

// is ILogger писать даже необязательно (но тогда не будет автоматической проверки реализации интерфейса)
contract Logger {
    mapping (address => uint[]) payments;

    function log(address _from, uint _amount) public {
        require(_from != address(0), " Zero address");

        payments[_from].push(_amount);
    }

    function getEntry(address _from, uint _index) public view returns(uint) {
        return payments[_from][_index];
    }
}