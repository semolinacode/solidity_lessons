// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    // у функций существует 4 области видимости:
    // 1) public - можно обращаться внутри и снаружи контракта
    // 2) external - внешняя, то есть можно обращаться только снаружи смарт контракта
    // например отправление средств через ММ, запросты через фронтенд итд
    // 3) internal - можно обращяться только из смарт самого контракта,
    // либо к ней могут обращаться контракты, которые унаследованы от этого контракта
    // 4) private - можно обращаться ТОЛЬКО из самого смарт контракта

    // После области видимости указывается модификатор view/pure
    // 1) view - значит, функция может только читать данные в блокчейне (модифицировать не может)
    // используется чтобы считать данные из смарт контракта (например баланс или какую-то переменную и вернуть её пользователю)
    // Таким образом, когда мы пишем view, значит, что функция может возвращать какое-то значение и 
    // функция вызывается через специальный call и за такой вызов клиент ничего не платит
    // 2) pure - чистая функция - по сути то же самое, что view, но функция не может читать никакие внешние данные (поля)
    // обычно pure используются как служебные функции для рассчета входных аргементов
    // 3) payable - означает, что функция может принимать денежные средства

    string public message = "hello world!!";
    uint public balance;

    // function getBalance() public view returns(uint) {
    //     return address(this).balance;
    // }

    // в returns мы можем дать имя переменной, которую хоиим вернуть (неявное возвращение значения)
    function getBalance() public view returns(uint newBalance) {
        // тип данных для balance не указываем, так как он уже указан в returns
        newBalance = address(this).balance;
        // return не пишем
    }

    // будет ошибка из-за pure
    // function getMessage() external pure returns(string memory) {
    //     return message;
    // }

    // все принимаемые аргументы - временные (они не могут быть storage)

    // функции, которые вызываются через транзакции (без view/pure) не могут возвращать значение напрямую
    // это не будет ошибкой, но значения получить от них мы не сможем
    // возвращают значения только в JS VM 
    // в hardhad в decoded output будет пусто
    // чтобы вернуть значение используется событие
    function setMessage(string memory newMessage) external returns(string memory) {
        message = newMessage;
        return message;
    }

    function pay() external payable {
        // value появляется только при наличии payable
        balance += msg.value;
    }

    // если в контракт просто прилетеют деньги на адрес (без указания метода смарт контракта)
    // по умолчанию деньги вернутся на счет отправителя
    // чтобы принимать деньги без вызова функций, используется receive 
    // эта функция называется fallback
    // "function" писать не надо 
    // external и payable обязательно
    receive() external payable {
        // может быть пустой
    }
    // remix IDE не отображает эту функцию
    // поэтому придется писать функцию-костыль типа pay

    // fallback вызывается, если относительно контракта была вызвана транзакция с неизвестным именем функции
    // payable указывать необязательно
    fallback() external payable {

    }
}