import React, { Component } from 'react';
import { ethers } from 'ethers';

import { ConnectWallet } from '../components/ConnectWallet';
import { WaitingForTransactionMessage } from '../components/WaitingForTransactionMessage';
import { TransactionErrorMessage } from '../components/TransactionErrorMessage';

import auctionAddress from '../contracts/DutchAuction-contract-address.json';
import auctionArtifact from '../contracts/DutchAuction.json';

// import { setIntervalAsync, clearsetIntervalAsync } from 'set-interval-async/dynamic';

const HARDHAT_NETWORK_ID = '1337';
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
            balance: null,
            currentPrice: null,
            stopped: false
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

        if (await this.updateStopped()) { return; }

        this.startingPrice = await this.auction.startingPrice();
        // умножаем на 1000 чтобы была правильная метка времени
        // превращаем в BigNumber так как startingPrice и discountRate уже BigNumber
        // this.startAt = ethers.BigNumber.from(await this.auction.startAt() * 1000);
        
        // из-за умножения на 1000 неправильно считалась цена
        this.startAt = await this.auction.startAt();
        this.discountRate = await this.auction.discountRate();


        // использовали setIntervalAsync когда были привязаны к блокчейну
        // this.checkPriceInterval = setIntervalAsync(async () => {
        //     this.setState({
        //         currentPrice: ethers.utils.formatEther(await this.auction.getPrice())
        //     });
        // }, 1000)

        this.checkPriceInterval = setInterval(async () => {
            // для взаимодействия с BigNumber нет математических операторов. Есть сспециальные методы типа sub, mul
            const elapsed = ethers.BigNumber.from(
                // делим на 1000 чтобы получить значение в секундах
                Math.floor(Date.now() / 1000)
                // Date.now()
            ).sub(this.startAt);
            const discount = this.discountRate.mul(elapsed);
            const newPrice = this.startingPrice.sub(discount);
            this.setState({
                currentPrice: ethers.utils.formatEther(newPrice)
            });
        }, 1000)

        // будем слушать событие Bought
        // есть проблема: этот метод может выплевывать старые события, которые произошли в прошлом
        const startBlockNumber = await this._provider.getBlockNumber();
        this.auction.on('Bought', (...args) => {
            // в последнем аргументе хранится информация о последнем событии
            const event = args[args.length - 1];
            if (event.blockNumber <= startBlockNumber) return;

            const price = args[0];
            const buyer = args[1];
            console.log(`Была совершена покупка ${buyer} по цене ${price}`);
            this.setState({
                stopped: true
            })
        })
    }

    updateStopped = async () => {
        const stopped = await this.auction.stopped();
        if (stopped) {
            clearInterval(this.checkPriceInterval);
        }
        this.setState({
            stopped: stopped
        });
        return stopped;
    }

    componentWillUnmount() {
        clearInterval(this.checkPriceInterval);
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
        if (window.ethereum.networkVersion === HARDHAT_NETWORK_ID) { return true; }
        this.setState({
            networkError: 'Please connect to localhost:8545'
        });
        return false;
    }

    _dismissNetworkError = () => {
        this.setState({
            networkError: null
        })
    }

    _dismissTransactionError = () => {
        this.setState({
            transactionError: null
        })
    }

    // функция для изменения блока в блокчейне (нужна так как изменение цены на аукционе привязано к timestamp блока)
    // nextBlock = async() => {
    //     await this.auction.nextBlock();
    // }
    
    buy = async() => {
        try {
            const tx = await this.auction.buy({
                value: ethers.utils.parseEther(this.state.currentPrice)
            });
            this.setState({
                txBeingSent: tx.hash
            });
            await tx.wait();
        } catch(error) {
            if (error.code === ERROR_CODE_TX_REJECTED_BY_USER) { return; }
            console.error(error);
            this.setState({
                transactionError: error
            });
        } finally {
            this.setState({
                txBeingSent: null
            });
            await this.updateBalance();
            await this.updateStopped();
        }
    }

    _getRpcErrorMessage(error) {
        if (error.data) {
            return error.data.message;
        }
        return error.message;
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

        if (this.state.stopped) {
            return <p>Auction stopped.</p>
        }

        // если кошелек выбран:
        return (
            <>
                {this.state.txBeingSent && (
                    <WaitingForTransactionMessage txHash={this.state.txBeingSent} />
                )}

                {this.state.transactionError && (
                    <TransactionErrorMessage
                        message={this._getRpcErrorMessage(this.state.transactionError)}
                        // так как _dismissTransactionError использует стрелочные функции, то тут стрелочные функции использовать не надо
                        // dismiss={() => this._dismissTransactionError()}
                        dismiss={this._dismissTransactionError}
                    />
                )}

                {this.state.balance && 
                <p>Your balance: {ethers.utils.formatEther(this.state.balance)} ETH</p>}

                {this.state.currentPrice &&
                    <div>
                        <p>Current item price: {this.state.currentPrice} ETH</p>
                        {/* <button onClick={this.nextBlock}>Next block</button> */}
                        {<button onClick={this.buy}>Buy!</button>}
                    </div>}
            </>
        )
    }
}
