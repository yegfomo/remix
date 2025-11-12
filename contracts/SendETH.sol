pragma solidity ^0.8.4;

contract SendETH{
    //构造函数 payable标注可以在部署的时候转eth进来
    constructor() payable {}
    receive() external payable {}

    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }


    error SendFailed(); // 用send发送ETH失败error

// send()发送ETH
function sendETH(address payable _to, uint256 amount) external payable{
    // 处理下send的返回值，如果失败，revert交易并发送error
    bool success = _to.send(amount);
    if(!success){
        revert SendFailed();
    }
}


error CallFaileds(); // 用call发送ETH失败error

// call()发送ETH
function callETH(address payable _to, uint256 amount) external payable{
    // 处理下call的返回值，如果失败，revert交易并发送error
    (bool success,) = _to.call{value: amount}("");
    if(!success){
        revert CallFaileds();
    }
}


}