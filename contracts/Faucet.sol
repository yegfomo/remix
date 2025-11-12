// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./IERC20.sol"; //import IERC20

//用户自己主动去领取，合约只检查“有没有领取过”、“时间到了没”
contract Faucet{
    //发放代币数量
    uint256 public amountAllowed = 100;

    //发放代币的地址
    address public tokenContract;

    //领取代币的地址
    mapping(address=>bool) public requestedAddress;

    //新增一个事件，记录每次领取代币的地址和数量
    event sendToken(address indexed Receiver,uint256 indexed Amount);

    //新增构造函数，初始化tokenContract
    constructor(address _contractAddress) {
        tokenContract = _contractAddress;
    }

    //调用领取代币
    function requestToken() external  {
        //每个地址只能领取一次（即使第一次这里也不会是null而是0，bool默认是false）
        require(!requestedAddress[msg.sender],"Can't Request Multiple Times!");
        //将ERC20地址转为ERC20对象
        IERC20 token = IERC20(tokenContract);
        //address(this).balance 只能看当前合约钱包的 ETH 余额。ETH 是系统自带的，不用 ERC20 合约管理。
        //ERC20 余额：由 ERC20 合约自己记录 → 必须向 token 合约查询
        //ERC20 代币不是系统自带的，是由某个合约管理的。这个合约内部有一个 mapping->balanceOf
        require(token.balanceOf(address(this))>=amountAllowed,"Faucet Empty!");

        token.transfer(msg.sender,amountAllowed);
        requestedAddress[msg.sender] = true; // 记录领取地址 
        //释放SendToken事件
        emit sendToken(msg.sender,amountAllowed);
    }


}