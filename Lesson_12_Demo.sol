// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./Lesson_12_Logger.sol";
// теперь необязательно подключать весь логгер. Достаточно подклчить интерфейс
import "./Lesson_12_ILogger.sol";

contract Demo {
    // объект связанный со смарт контрактом Logger из файла Lesson_12.sol
    // Logger logger;

    ILogger logger;

    constructor(address _logger) {
        // преобразовываем адрес в объект logger через который будет взаимодействовать со смарт контрактом
        // logger = Logger(_logger);

        // Получается, если в контракте есть функции из интерфейса, можно использовать интерфейс для взаимодействия
        // при этом тому контракту даже не надо наследоваться от интерфейса
        logger = ILogger(_logger);
    }

    function payment(address _from, uint _number) public view returns(uint) {
        return logger.getEntry(_from, _number);
    }

    receive() external payable {
        logger.log(msg.sender, msg.value);
    }
}
