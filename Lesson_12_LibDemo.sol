// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// импортируем файл с библиотеками
import "./Lesson_12_Ext.sol";

contract LibDemo {
    // подключение библиотеки (добавляем новые методы к типу данных str)
    // пожно подключить определенные функции из библиотеки, указав их в фигурных скобках после using
    using StrExt for string;
    // теперь все строки в смарт контракте имеют новую функцию eq
    using ArrayExt for uint[];

    function runnerStr(string memory str1, string memory str2) public pure returns(bool) {
        // 1 способ:
        return str1.eq(str2);

        // 2 способ:
        // return StrExt.eq(str1, str2);
    }

    function runnerArr(uint[] memory numbers, uint el) public pure returns(bool) {
        return numbers.inArray(el);
    }
}
