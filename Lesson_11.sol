// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    // constructor() {
    //     owner = msg.sender;
    // }

    constructor(address ownerOverride) {
        owner = ownerOverride == address(0)? msg.sender: ownerOverride;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    // функция переводит все деньги владельцу (будем её переопределять в Balances)
    // чтобы переопределить функцию ниже по иерархии, нужно добавить к ней ключевое слово virtual
    function withdraw(address payable _to) public virtual onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

// конструктор в контракте Ownable принимает параметр, а мы этот параметр внутри контракта Balances нигде не передаем
// соответственно мы должны пометить контракт Balances как абстрактный 
// Абстрактные контракты нельзя разворачивать самостоятельно
abstract contract Balances is Ownable {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // так как это переопределенная функция, к ней нужно добавить ключевое слово override
    // так же можно добавить virtual, что позволит опять переопределить эту функцию ниже по иерархии
    
    // onlyOwner можно не писать. Модификаторы унаследуются автоматически
    function withdraw(address payable _to) public override virtual onlyOwner {
        _to.transfer(getBalance());
    }
}

// наследование работает как и в других ЯПах, только с ключевым словом "is"
// деплоить можно только основной контракт (родительский не надо)

// возможно множественное наследование через запятую
// Порядок наследования очень важен. Если будет Balances, Ownable, то будет ошибка (так как по иерархии Ownable стоит выше и Balances наследуется от Ownable)
// По сути нам не обязательно наследоваться от Ownable так как Balances уже наследуется от Ownable и значит функционал Ownable нам будет доступен

// Конструктор Ownable принимает параметр => мы должны передать аргумент

// 1 способ:
// contract MyContract is Ownable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), Balances {

// но бывают случаи, когда аргемент должен быть динамическим
// 2 способ:
contract MyContract is Ownable, Balances {
    // // переопределяем родительский конструктор
    constructor() Ownable(msg.sender) {
    // // либо сделать так:
    // constructor(_owner) Ownable(_owner) {
    // // если бы у Balances тоже был конструктор, мы бы передавали туда аргументы так (при этом порядок следования не важен):
    // constructor(_owner) Ownable(_owner) Balances(...) {
    }

    // // В случае, когда конструктор в родительском контракте без параметров, мы можем сделать так:
    // constructor(address _owner) {
    //     owner = _owner;
    // }
    // // В этой ситуации при развертывании MyContract сначала вызывается конструктор родителя, а потом вызывается наш конструктор (не самый лучший вариант)

    // private функции недоступны в потомках
    // internal функции можно вызывать изнутри родителя и изнутри потомков, но не извне
    // external как обычно можно вызывать только снаружи 
    // public вызывается отовсюду
    // Переменные работают аналогично

    // непонятно какую функцию withdraw использовать
    // поэтому переопределяем её тут)
    // при переопределении нужно явно указать в скобках для каких контрактов мы переопределяем эту функци/
    // так как функция есть в обоих родителях, пишем в скобках Ownable, Balances (порядок следования неважен)
    function withdraw(address payable _to) public override(Ownable, Balances) onlyOwner {
        // дублирующийся код
        // _to.transfer(getBalance());

        // чтобы избежать дублирования кода, будем обращаться к родительским методам
        // 1 способ:
        // Balances.withdraw(_to);

        // 2 способ:
        // чтобы не указывать явно на каком родителе вызываем функцию, можно использовать ключевое слово "super"
        // super говорит, что нужно подняться на 1 уровень иерархии вверх и вызвать функцию на этом смарт контракте
        // так как у нас в определении контракта порядок указан как Ownable, Balances, значит предыдущий уровень иерархии Balances
        super.withdraw(_to);
    }

    // у функций ниже по иерархии при переопределении не должна меняться облась видимости

    // контракты можно разносить по разным файлам и добавлять к себе в проект с помощью:
    // import "path";
}
