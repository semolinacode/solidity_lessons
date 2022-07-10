// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    // за хранение информации в блокчейне берутся деньги
    string public myStr = "test";

    // значение типа данных address указывается без кавычек
    address public myAddr = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // Тип данных mapping - по сути словарь (но строготипизированный)
    // при обращении к несуществующему ключу, получим значение по умолчанию (в нашем случае 0)
    // на самом деле это работает сложнее - читать в документации
    // ключами могут быть любые типы данных
    // в качестве значений могут быть другие mapping'и (вложенность), могут быть массивы, сложные структуры данных итп
    // сложная структура данных не может быть ключом
    // у mapping'ов как и у строк нет понятия "длина"
    mapping (address => uint) public payments;

    function demo() public {
        // для строк нужно указывать хранилище данных с помощью ключевого слова "storage", "memory" или "calldata"
        // напоминает указатель
        string memory myTmpStr = "temp";
        myStr = myTmpStr;
    }

    // передача строк в функцию
    function demo2(string memory newValueStr) public {
        myStr = newValueStr;
    }

    // В солидите нет конкатенации строк
    // нет сравнения строк
    // нельзя обращаться к элементам строки по индексу

    // свойства адресов:
    // balance

    // Методы адресов:
    // transfer(amount) - переводит деньги с текущего адреса (с контракта)

    // Ключевое слово "view" говорит, что функция будет вызываться не через транзакцию, а через вызов
    // returns(тип_данных) указывает функции тип возвращаемого значения
    function getBalance(address targetAddress) public view returns(uint) {
        return targetAddress.balance;
    }

    // payable - говорит, что этот адрес может принимать деньги
    // 1 способ:
    // function transferTo(address payable targetAddress, uint amount) public {
    function transferTo(address targetAddress, uint amount) public {
        // targetAddress.transfer(amount);

        // 2 способ:
        address payable _to = payable(targetAddress);
        _to.transfer(amount);
    }

    function receiveFunds() public payable {
        // можно ничего не писать
        // так как из-за слова payable деньги автоматически зачислятся на смарт контракт
    }

    function sendEther() public payable {
        // msg -  глобальный объект с информацией о транзакции
        // value доступен только в payable функциях
        payments[msg.sender] = msg.value;
    }
}
