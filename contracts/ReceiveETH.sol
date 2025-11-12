pragma solidity ^0.8.4;

contract ReceiveETH{
    //定义事件记录amout和gas
    event Logs(uint amount,uint gas);

    //receive 方法，接收eth时被触发
    receive() external payable {
        emit Logs(msg.value,gasleft());
    }

    // 返回合约ETH余额
    function getBalance() view public returns(uint){
        return address(this).balance;
    }
}