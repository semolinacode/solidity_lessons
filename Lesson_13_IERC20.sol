// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    // позвращает имя токена (например для ММ)
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    // сколько будет знаков после запятой (если 18, то 1 токен = 1 wei)
    function decimals() external view returns(uint);

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    // перевод с кошелька инициатора транзакции на другой адрес 
    function transfer(address to, uint amount) external;

    // нужно чтобы мы могли проверить может ли сторонний аккаунт списать с моего счета что-то списать в свою пользу
    // например сторонний контракт "магазин" будет списывать с нас нужное кол-во токенов, которое мы хотим продать
    // _owner - владелец кошелька
    function allowance(address _owner, address spender) external view returns(uint);

    // кто может списывать токены и в каком кол-ве
    function approve(address spender, uint amount) external;

    // должна работать только после approve
    function transferFrom(address sender, address recipient, uint amount) external;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    
    event Approve(address indexed owner, address indexed to, uint amount);
}
