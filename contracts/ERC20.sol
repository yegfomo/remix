// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract ERC20 is IERC20 {

    //剩余金额
    mapping(address=>uint256) public override balanceOf;

    //owner给spender账户的授权额度
    mapping(address=>mapping(address=>uint256)) public override allowance;

    //余额
    uint256 public override totalSupply;

    string public name; //名称

    string public symbol; //符号

    uint8 public decimals = 18;//小数位数

    //在合约部署的时候实现合约名称和符号
    constructor(string memory name_,string memory symbol_){
        name = name_;
        symbol = symbol_;
    }


    //实现tranfer逻辑，代币转账逻辑
    function transfer(address recipient,uint amount) public override returns(bool){
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] +=amount;
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }

    //实现approve批准函数，代币授权逻辑
    //msg.sender → 调用 approve 的人（代币拥有者）,spender → 被授权花钱的人,amount → 授权额度
    function approve(address spender,uint amount) public override returns(bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    
    //实现transferFrom函数，代币授权转账逻辑(这里的调用人不一样，是B消费者调用)
    function transferFrom(address sender,address recipient,uint amount) public override returns(bool){
        //sender 是代币真正的 owner
        //msg.sender 是执行 transferFrom 的 spender（你自己或某个合约）
        allowance[sender][msg.sender] -=amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] +=amount;
        emit Transfer(sender,recipient,amount);
        return true;

    }

    //铸造代币，从0地址转账给调用者地址
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
    }


    //销毁代币，从调用者地址转账给0地址
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender,address(0),amount);
    }


}