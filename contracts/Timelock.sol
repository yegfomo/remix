// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
时间锁主要有三个功能：
创建交易，并加入到时间锁队列。
在交易的锁定期满后，执行交易。
后悔了，取消时间锁队列中的某些交易。
项目方一般会把时间锁合约设为重要合约的管理员，例如金库合约，再通过时间锁操作他们。
时间锁合约的管理员一般为项目的多签钱包，保证去中心化。
*/
contract Timelock{
    // 交易取消事件
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // 交易执行事件
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // 交易创建并进入时间锁队列的事件
    event QueueTransaction(bytes32 indexed txHash,address indexed target,uint value,string signature, bytes data, uint executeTime);
    // 修改管理员地址的事件
    event NewAdmin(address indexed newAdmin);

    address public admin; // 管理员地址

    uint public constant  GRACE_PERIOD = 7 days; 
    uint public delay; // 交易锁定时间 （秒）
    mapping (bytes32 => bool) public queuedTransactions; // txHash到bool，记录所有在时间锁队列中的交易

    //Timelock有两个修饰器
    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // onlyTimelock modifier
    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }

    /**
     * @dev 构造函数，初始化交易锁定时间 （秒）和管理员地址
     */
    constructor(uint delay_){
        delay = delay_;
        admin = msg.sender;
    }

     /**
     * @dev 改变管理员地址，调用者必须是Timelock合约。
     */
     functio changeAdmin(address newAdmin) public onlyTimelock{
        admin = newAdmin;
        emit NewAdmin(newAdmin);
     }

    /**
     * @dev 创建交易并添加到时间锁队列中。
     * @param target: 目标合约地址
     * @param value: 发送eth数额
     * @param signature: 要调用的函数签名（function signature）
     * @param data: call data，里面是一些参数
     * @param executeTime: 交易执行的区块链时间戳
     *
     * 要求：executeTime 大于 当前区块链时间戳+delay
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
        // 检查：交易执行时间满足锁定时间
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // 计算交易的唯一识别符：一堆东西的hash


    }

      /**
     * @dev 取消特定交易。
     *
     * 要求：交易在时间锁队列中
     */



}