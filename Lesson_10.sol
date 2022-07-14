// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AucEngine {
    // Владелец движка. Ему будем зачислять выручку
    address public owner;
    // кроме constant есть оператор immutable
    // immutable - работает как константа, но значение можно определять не сразу, а например, в конструкторе
    // days конвертируются в секунды
    uint constant DURATION = 2 days;
    uint constant FEE = 10; // 10%

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stoped;
    }

    Auction[] public auctions;

    constructor() {
        owner = msg.sender;
    }

    // здесь не надо писать memory так как тут просто описываем поля
    event AuctionCreated(uint index, string itemName, uint startingPrice, uint duration);
    event AuctionEnded(uint index, uint finalPrice, address winner);


    // calldata - неизменяемое временное хранилище
    function createAuction(uint _startingPrice, uint _discountRate, string calldata _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;
        // проверка чтобы цена не ушла в минус
        require(_startingPrice >= _discountRate * duration, "Incorrect starting price");

        // фигурные скобки позволяют заполненять структуру по полям
        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            // будет пересчитана в другой функции
            finalPrice: 0,
            discountRate: _discountRate,
            startAt: block.timestamp, // раньше писали now. Но сейчас нежелательно
            endsAt: block.timestamp + duration,
            item: _item,
            stoped: false
        });
        auctions.push(newAuction);
        emit AuctionCreated(auctions.length - 1, _item, _startingPrice, _duration);
    }

    // брать цену с аукциона в текущий момент времени
    function getPriceFor(uint _index) public view returns(uint) {
        Auction memory cAuction = auctions[_index];
        require(!cAuction.stoped, "Stopped");
        // сколько прошло времени
        uint elapsed = block.timestamp - cAuction.startAt;
        // сколько скинуть в зависимости от времени
        uint discount = elapsed * cAuction.discountRate;
        return cAuction.startingPrice - discount;
    }

    function stop(uint _index) public {
        Auction storage cAuction = auctions[_index];
        cAuction.stoped = true;
    }

    function buy(uint _index) external payable {
        // memory означает, что текущий аукцион модифицируется только в памяти
        // Но нам нужно не только модифицировать, но и сохранить результат (иначе даже cAuction.stoped = true; не будет иметь значения)
        Auction storage cAuction = auctions[_index];
        require(!cAuction.stoped, "Stopped");
        require(block.timestamp < cAuction.endsAt, "Ended");
        uint cPrice = getPriceFor(_index);
        require(msg.value >= cPrice, "Not enought funds");
        cAuction.stoped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        // тут обязательно сначала умножаем и потом делим
        // иначе будет дробное число и словим ошибку
        cAuction.seller.transfer(cPrice - ((cPrice * FEE) / 100));
        emit AuctionEnded(_index, cPrice, msg.sender);
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrowFunds(uint funds) external {
        require(msg.sender == owner, "You are not owner");
        require(funds <= address(this).balance, "Not enought money on the contract");
        payable(owner).transfer(funds);
    }
}
