// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    // Инструкции, проверяющие условие.
    // Если условие не выполняется, транзакция откачивается
    // require - принимает 2 параметра: 1) условное выражение; 2) сообщение об ошибке, которое мы выведем, если условие не выполняется
    // за кулисами функция require вызывает функцию revert

    // revert - принимает работает как exit() в python. Принимает 1 аргумент - сообщение об ошибки
    // то есть мы должны самостоятельно написать условие через if/else и вызвать revert 

    // ошибка которая возникаеи при вызове require, revert может возникать при вызове функции смарт контракта, в котором нет никакого кода
    // или если в контракт приходят деньги, а функция не payable
    // или деньги приходят в функцию view/pure

    // assert - более суровая функция. Принимает только условное выражение
    // вызывает ошибку типа Panic. Эта ошибка возникает в тех случаях, когда в контракте происходит что-то совсем плохое (типа деления на 0)
    // Обычно с помощью assert проверяют условие, которое не должно произойти вообще никогда (вместо сообщения кидает "общий" текст ошибки)

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function pay() public payable {
        // в этот момент в журнал событий (который хранится вместе с блокчейном) будет записано новое событие с этой информацией
        // за хранение данных в журнале событий мы не платим так же много как за хранение в блокчейне 
        // Можем через EthersJS подписаться на журнал событий и когда это событие наступает, можем обработать его на бекенде
        // Но внутри смартконтракта мы не можем читать журнал событий
        emit Paid(msg.sender, msg.value, block.timestamp);
    }

    // onlyOwner - кастомный модификатор
    function withdraw(address payable _to) external onlyOwner notNullAddress(_to) {
        // хотим чтобы только владелец мог списывать деньги с контракта
    
        // require(msg.sender == owner, "You are not an owner!!");

        // то же самое, что написано сверху
        // if (msg.sender != owner) {
        //     revert("You are not an owner!!");
        // } else {
        //     // ...
        // }

        _to.transfer(address(this).balance);
    }

    // можно написать собственный модификатор и пристыковать его к функции
    modifier onlyOwner() {
        // внутри пишем проверку, которую хотим совершить
        require(msg.sender == owner, "You are not an owner!!");
        // _; - на этой строчке мы выходим из модификатора и начинаем выполнять тело функции
        _;
        // после тела функции тоже можно делать проверки
    }

    // модификатор может принимать аргументы
    modifier notNullAddress(address _to) {
        // address(0) - нулевой адрес (адрес по умолчанию) - является значением по умолчанию для переменной типа address
        require(_to != address(0), "Incorrect address!!");
        _;
    }

    // СОБЫТИЯ: используеются, когда нужно "внешнему миру" сказать, что у нас что-то произошло
    // Создадим событие, которое будет вызвано при зачислении средств на контракт
    // чтобы породить событие используется emit

    // параметры - поля события (могут быть любые)
    // некоторые поля можно пометить как индексированные с помощью ключевого слова indexed
    // по индексированным полям можно реализовывать поиск
    // в одном событии может быть индексировано ДО 3-х полей
    event Paid(address indexed _from, uint _amount, uint _timestamp);

    receive() external payable {
        pay();
    }
}
