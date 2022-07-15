// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILogger {
    // в интерфейсе нельзя писать public (только external)
    function log(address _from, uint _amount) external;
    function getEntry(address _from, uint _index) external view returns(uint);
}
