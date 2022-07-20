import React, { Component } from 'react';
import { ethers } from 'ethers';

import { ConnectWallet } from '../components/ConnectWallet';

import auctionAddress from '../contracts/DutchAuction-contract-address.json';
import auctionArtifact from '../contracts/DutchAuction.json';

const HARDHAT_NETWORK_ID = '31337';
// будет использоваться при обработке транзакции (например если юзер отправил транзакцию, но потом отменил её через мм)
const ERROR_CODE_TX_REJECTED_BY_USER = 4001;

export default class extends Component {
    constructor(props) {
        super(props);
        this.initialState = {
            selectedAccount: null, 
            txBeingSent: null, 
            networkError: null, 
            transactionError: null, 
            balance: null
        }

        this.state = this.initialState
    }

    // используем специальный синтаксис чтобы был доступ к this
    _connectWallet = async () => {
        // Если мм не обраружен
        if (window.ethereum === undefined) {
            this.setState({
                networkError: 'Please install MetaMask'
            });
            return;
        }

        // предлагаем пользователю выбрать адрес с которого он хочет работать
        const [selectedAddress] = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });

        // проверяем сеть мм
        if(!this._checkNetwork()) { return; }

        this._initialize(selectedAddress);

        // если пользователь поменял аккаунт, то берем новый вдрес, который был выбран юзером
        window.ethereum.on('accountsChanged', ([newAddress]) => {
            if (newAddress === undefined) {
                // возвращение к изначальному состоянию
                return this._resetState();
            }
            // реинициализация с новым адресом
            this._initialize(newAddress);
        })

        // если пользователь поменять сеть в мм
        window.ethereum.on('chainChanged', ([networkId]) => {
            this._resetState();
        })
    }

    _resetState() {
        this.setState(this.initialState)
    }

    async _initialize(selectedAddress) {
        // то, через что мы будем работать с блокчейном
        // по сути будем рабоать просто с мм (window.ethereum)
        this._provider = new ethers.providers.Web3Provider(window.ethereum);

        // подключаемся к контракту
        this.auction = new ethers.Contract(
            auctionAddress.DutchAuction,
            auctionArtifact.abi,
            // от имени кого будем подключаться
            this._provider.getSigner(0)
        );

        this.setState({
            selectedAccount: selectedAddress
        }, async () => {
            // обновляем баланс
            await this.updateBalance()
        })
    }

    async updateBalance() {
        const newBalance = (await this._provider.getBalance(
            this.state.selectedAccount
        )).toString();
 
        this.setState({
            balance: newBalance
        })
    }

    // доступ к this не нужен поэтому пишем без специального синтаксиса
    _checkNetwork() {
        // просто проверяем id сети
        console.log(window.ethereum.networkVersion);
        if (window.ethereum.networkVersion === HARDHAT_NETWORK_ID) { return true; }
        this.setState({
            networkError: 'Please connect to localhost:8545'
        });
        return false;
    }

    _dismissNetworkError() {
        this.setState({
            networkError: null
        })
    }

    render() {
        if (!this.state.selectedAccount) {
            // возвращаем компонент, который недавно написали (передаем в него параметры)
            return <ConnectWallet
                connectWallet={this._connectWallet}
                networkError={this.state.networkError}
                dismiss={this._dismissNetworkError}
            />
        }

        // если кошелек выбран:
        return (
            <>
                {this.state.balance && 
                <p>Your balance: {ethers.utils.formatEther(this.state.balance)} ETH</p>}
            </>
        )
    }
}
