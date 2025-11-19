// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
以太币本身并不符合ERC20标准。WETH的开发是为了提高区块链之间的互操作性 ，
并使ETH可用于去中心化应用程序（dApps）。它就像是给原生代币穿了一件智能合约做的衣服：
穿上衣服的时候，就变成了WETH，符合ERC20同质化代币标准，可以跨链，可以用于dApp；脱下衣服，它可1:1兑换ETH。

ETH (原生以太币)
    它是以太坊区块链的**原生“燃料”**和货币。
    它是在 ERC20 标准之前就存在的。
    它不是一个智能合约。
    它没有 transfer()、approve()、balanceOf() 这些 ERC20 函数。
    它的转账是通过 payable(..).transfer() 这种特殊语法完成的。
ERC20 (代币标准)
    这是在以太坊上创建“代币”的一套统一规范（一个接口）。
    像 USDT, LINK, UNI 这些都是 ERC20 代币，它们都是智能合约。
    它们都有 transfer()、approve()、transferFrom() 等标准函数。

想象一下 Uniswap（一个去中心化交易所，DEX）。
    Uniswap 是一个智能合约，它的设计目的是帮助用户交换任何 ERC20 代币。
    Uniswap 的代码逻辑是：“你 (用户) 先 approve (批准) 我，允许我从你钱包里拿走 100 个 LINK，然后我再 transfer (转移) 50 个 UNI 给你。”
    这套逻辑对所有 ERC20 代币都有效。
    但是，这套逻辑对 ETH 无效！
    Uniswap 的合约不能调用 ETH 的 approve() 或 transferFrom()，因为 ETH 根本没有这些函数。
    这意味着 Uniswap 必须为 ETH 重写一套完全不同的、特殊的逻辑，这会使合约变得极其复杂、臃肿且容易出错。
    
ETH： 原生币，没有 ERC20 接口，无法在 DeFi 合约中“批准/转移”。
WETH： ERC20 代币（智能合约），1:1 锚定 ETH，拥有 ERC20 接口，可以在所有 DeFi 应用中无缝使用。

目前在用的主网WETH合约写于2015年，非常老，那时候solidity是0.4版本。我们用0.8版本重新写一个WETH。
*/
contract WETH is ERC20{
    //事件：存款和取款
    event Deposit(address indexed dst,uint wad);
     event  Withdrawal(address indexed src, uint wad);

    // 构造函数，初始化ERC20的名字和代号
    constructor() ERC20("WETH", "WETH"){
    }

    // 回调函数，当用户往WETH合约转ETH时，会触发deposit()函数
    //当有人调用了合约上一个不存在的函数时（msg.data 非空但无法匹配），fallback() 会被触发。
    fallback() external payable {
        deposit();
    }
    // 回调函数，当用户往WETH合约转ETH时，会触发deposit()函数
    //当有人向合约发送 ETH，并且没有附加任何数据（msg.data 是空的）时，receive() 会被触发。
    receive() external payable {
        deposit();
    }

    // 存款函数，当用户存入ETH时，给他铸造等量的WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    // 提款函数，用户销毁WETH，取回等量的ETH
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }


    
}