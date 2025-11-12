// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* @dev ERC20接口合约
*/
interface IERC20 {

    //释放条件：当value单位的货比从账户from转账到另一个账户to时.
    //加了indexed之后可被区块链节点索引，从而支持通过该字段过滤事件日志
    event Transfer(address indexed from,address indexed to,uint256 value);

    //释放条件：当value单位的货比从账户owner授权给另一个账户spender(消费者)时
    event Approval(address indexed owner,address indexed spender,uint256 value);

    //返回代笔总供给
    function totalSupply() external view returns(uint256);

    //返回账户accout所持有的代币数
    function balanceOf(address account) external view returns(uint256);

    //转账：从调用者账户--》到另一账户to，转amount数量
    //如果成功返回true
    //释放Transfer事件
    function transfer(address to,uint256 amount) external returns(bool);

    //查询owner给spender账户的授权额度，默认为0
    //当approve 和 transferFrom 被调用时，allowance会改变
    function allowance(address owner,address spender) external view returns (uint256);

    //调用者账户给spener账户授权amout数量代币
    //如果成功返回true
    //释放approval事件
    function approve(address spender,uint256 amount) external returns(bool);

    //通过授权机制，从from账户向to账户转账amout数量代币，转账的部分会从调用者的
    //allowance里扣除
    //如果成功返回true
    //释放transfer事件
    function transferFrom(address from,address to,uint256 amount) external returns(bool);



    
}