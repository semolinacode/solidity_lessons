// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Оптимизация смарт-контрактов и газ
// 1) Чем меньше функций и переменных, тем лучше
// 2) Использовать значение по-умолчанию (особенно для переменных состояния)
// 3) Память состоит из ячеек по 32 байта. Поэтому переменные желательно объявлять так, чтобы они расходывали все 32 байта
// 4) Лучше использовать uint, чем uint8 итп (так как не надо дополнительно обрезать ячейку в памяти)
// 5) При инициализации переменных состояния желательно задавать им статическое значение, а не рассчитывать их
// 6) Не заводить лишних промежуточных переменных
// 7) Лучше использовать mapping вместо массива (особенно динамических). Почти в 2 раза будет разница
// 8) Чем меньше размерность элементов массива, тем дешевле
// 9) В солидити лучше не делать кучу маленьких функций, которые вызывают друг друга
// 10) Не желательно использовать слишком большие строки (желательно чтобы строка помещалась в 32 байта)
// 11) Не желательно модифицировать много раз одну переменную состояния (например, не менять в цикле)
// 12) В блокчейне желательно не хранить большие объемы данных
// 13) Писать компактный код без лишнего

contract Op {
    uint demo; // 67066

    // a и b займут одну ячейку 32 байта
    uint128 a = 1; // 113528
    uint128 b = 2;
    uint256 c = 3;

    uint demo2 = 1; // 89240

    bytes32 public hash = 0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658; // 114791

    // 140245 за развертывание и 23501 за использование функции
    mapping (address => uint) payments; 
    function pay() external payable {
        require(msg.sender != address(0), "Zero address!!");
        payments[msg.sender] = msg.value;
    }

    // 141133 за развертывание и 23441 за транзакцию
    uint[10] payments2;
    function pay2() external payable {
        require(msg.sender != address(0), "Zero address!!");
        payments2[0] = msg.value;
    }

    uint8[] demo3 = [1, 2, 3]; // 127260

    // 46125 газа за операцию
    uint c2 = 5;
    uint d2;
    function calc() public {
        uint a2 = 1 + c2;
        uint b2 = 2 * c2;
        d2 = a2 + b2;
    }

    // 29698 газа за использование функции
    uint public result = 1;
    function doWork(uint[] memory data) public {
        uint temp = 1;
        for (uint i; i < data.length; i++) {
            temp *= data[i];
        }
        result = temp;
    }
}

contract Un {
    uint demo = 0; // 69324

    // у a и b будут незаполненные ячейки
    uint128 a = 1; // 135362
    uint256 c = 3;
    uint128 b = 2;

    // эта операция по газу будет дороже. Так как в начале нужно правильно урезать переменную
    uint8 demo2 = 1; // 89629

    bytes32 public hash = keccak256(abi.encodePacked("test")); // 116440

    // 141529 за развертывание и 23515 за использование функции
    mapping (address => uint) payments;
    function pay2() external payable {
        address _from = msg.sender;
        require(_from != address(0), "Zero address!!");
        payments[_from] = msg.value;
    }

    // 134587 за развертывание и 48421 за транзакцию
    uint[] payments2;
    function pay() external payable {
        require(msg.sender != address(0), "Zero address!!");
        payments2.push(msg.value);
    }

    uint[] demo3 = [1, 2, 3]; // 158612

    // 46158 газа за операцию
    uint c2 = 5;
    uint d2;
    function calc() public {
        uint a2 = 1 + c2;
        uint b2 = 2 * c2;
        calc2(a2, b2);
    }

    function calc2(uint a2, uint b2) private {
        d2 = a2 + b2;
    }


    // 30198 газа за использование функции
    uint public result = 1;
    function doWork(uint[] memory data) public {
        for (uint i; i < data.length; i++) {
            result *= data[i];
        }
    }
}