// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    // Enum
    enum Status {
        Paid,
        Delivered,
        Received
    }

    // значение по-умолчанию: Paid (0)
    Status public currentStatus;

    function deliver() public {
        // обращение через точку
        currentStatus = Status.Delivered;
    }


    // Array
    // uint[10] public items = [1, 2, 3];
    uint[10] public items = [1, 2, 3];

    // двумерные массивы
    // !!!!! первый индекс отвечает за длину вложенного массива
    // !!!!! второй индекс отвечает за длину внешнего массива
    uint[3][2] public arrs;

    // динамические массивы
    uint public len;
    uint[] public arr2;

    function initialization() public {
        items[0] = 100;
        items[4] = 555;
        items[6] = 124;
        items[8] = 65;
        items[9] = 9122;
    }

    function demo() public {
        arrs = [
            [3, 4, 5], 
            [6, 7, 8]
        ];
        // у 6 будет индекс [1][0]
    }

    function addElement() public {
        // добавить элемент в конец массива
        arr2.push(12);
        // посмотреть длину массива
        len = arr2.length;
    }

    function sampleMemory() public view returns(uint[] memory) {
        // создаемм массив в памяти, а не блокчейне
        // указываем размерность массива в круглых скобках
        uint[] memory tempArr = new uint[](10);
        tempArr[0] = 12;
        return tempArr;
    }


    // Массивы байт
    // эта переменная, которая будет иметь размерность ровно 1 байт
    // информация будет храниться в виде последовательности байт
    // размерность меняется от 1 до 32 байт
    
    // bytes1 public myVar;
    
    // можно хранить строки (но они будут закодированы как последовательность байт)
    // длина такого массива = 32
    bytes32 public myVar = "test here";

    // динамические массивы байт
    // в этом случае не будет лишних нулей в конце
    // длина такого массива = 9
    bytes public myDynVar = "test here";

    // нельзя присваивать кириллицу просто так. Нужно обязательно писать unicode
    bytes public checkRu = unicode"Привет мир!!";

    // в отличии от обычных строк, байтовые массивы позволяют мерить длину
    function getLength() public view returns(uint256) {
        // хорошо работает только с латиницей
        // return myDynVar.length;
        return checkRu.length;
    }

    // возвращаем байты
    function getByte() public view returns(bytes1) {
        // в данном случае вернется 0x74, то есть буква "t"
        return myDynVar[0];
    }


    // Струкруты
    struct Payment {
        // нельзя делать рукурсивные типы 
        uint amount;
        uint timestamp;
        address from;
        // тут не нужно писать memory
        string message;
    }

    struct Balance {
        uint totalPayments;
        mapping(uint => Payment) payments;
    }

    mapping(address => Balance) public balances;

    // при получении платежя, будем сохранять информацию о нем
    function pay(string memory message) public payable {
        uint paymentNumber = balances[msg.sender].totalPayments;
        // пришел +1 платеж
        balances[msg.sender].totalPayments++;

        // временная переменная 
        Payment memory newPayment = Payment(
            msg.value, 
            // метку времени берем из блока
            block.timestamp,
            msg.sender, 
            message
        );
        balances[msg.sender].payments[paymentNumber] = newPayment;
    }

    function getPayment(address _addr, uint _index) public view returns(Payment memory) {
        return balances[_addr].payments[_index];
    }
}
