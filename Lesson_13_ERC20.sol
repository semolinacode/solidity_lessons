// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Lesson_13_IERC20.sol";

contract ERC20 is IERC20 {
// contract ERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    // храним информацию, что с какого-то кошелька можно списать на другой кошелек какое-то кол-во токенов
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;
    uint _decimals;

    constructor(string memory name_, string memory symbol_, uint initialSupply, address shop) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        // переводим все токены на адрес магазина
        mint(initialSupply, shop);
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external view returns(uint) {
        return _decimals; // 1 token = 1 wei
    }
    
    function totalSupply() external view returns(uint) {
        return totalTokens;
    }

    // в интерфейса все функции должны быть external
    // но balanceOf мы используем внутри контракта. Поэтому будем писать public
    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }

    // это не часть стандарта (просто распространенное решение)
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {
        // тут будут проверки, которые нужно сделать перед отправкой токенов
    }

    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function allowance(address _owner, address spender) public view returns(uint) {
        // _owner - владелец кошелька
        // spender - адрес, который может списать с нас какое-то кол-во токенов
        return allowances[_owner][spender];
    }

    function _approve(address sender, address spender, uint amount) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public enoughTokens(sender, amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        require(allowances[sender][recipient] >= amount, "Check allowance");
        // если изначально там 0 токенов, то будет ошибка так как используется uint
        allowances[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount; 
        emit Transfer(sender, recipient, amount);
    }

    function mint(uint amount, address shop) public onlyOwner {
        _beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function birn(address _from, uint amount) public onlyOwner {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }
}

// создаем токен
contract MCSToken is ERC20 {
    constructor(address shop) ERC20("MCSToken", "MCT", 20, shop) {

    }
}

contract MShop {
    // в магазине нужен адрес токена, который будем продавать
    // в виде объекта, реализующего интерфейн IERC20
    IERC20 public token;
    // владелец магазина
    address payable public owner;
    event Bought(uint _amount, address indexed _buyer);
    event Sold(uint amount, address indexed _seller);

    constructor() {
        // new позволяет развернуть сторонний смарт контракт
        token = new MCSToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

    function sell(uint _amountToSell) external {
        require(_amountToSell > 0 && token.balanceOf(msg.sender) >= _amountToSell, "Incorrect amount!!");
        // чтобы что-то продать инициатор должен разрешить магазину изъять у него эти токены
        // проверяем allowance
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "Check allowance");

        token.transferFrom(msg.sender, address(this), _amountToSell);
        payable(msg.sender).transfer(_amountToSell);
        // кроме функции transfer еще есть call и send
        // call - низкоуровневый вызов (можем отправлять и данные и транзакции в поле data или только value)
        // так же в call мы можем указать лимит по газу (используем если в другом контракте какая-то сложная функция, принимающая деньги)
        // например transfer резервирует максимум 2300 газа (на перевод денежных средств)
        // send - то же самое что и transfer, но не пораждает ошибку, если деньги не дошли (просто возвращает false)

        emit Sold(_amountToSell, msg.sender);
    }

    // функция для покупки токенов
    receive() external payable {
        uint tokensToBuy = msg.value; // 1 wei = 1 token (в ином случае нужно пересчитывать value)
        require(tokensToBuy > 0, "Not enough funds");

        require(tokenBalance() >= tokensToBuy, "Not enough tokens");

        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    }

    function tokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function getFundsBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawTokens(address _to, uint _amount) public onlyOwner {
        require(getFundsBalance() >= _amount, "Not enough funds");
        payable(_to).transfer(_amount);
    }
}
