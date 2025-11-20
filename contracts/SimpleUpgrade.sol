// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 简单的可升级合约，管理员可以通过升级函数更改逻辑合约地址，从而改变合约的逻辑。
// 教学演示用，不要用在生产环境
contract SimpleUpgrade {
    address public implementation;
    address public admin;

    // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

     // fallback函数，将调用委托给逻辑合约
     //我们没有在它的fallback()函数中使用内联汇编，而仅仅用了implementation.delegatecall(msg.data);。因此，回调函数没有返回值，但足够教学使用了。
     fallback() external payable{
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
     }

      // 升级函数，改变逻辑合约地址，只能由admin调用
     function upgrade(address newImplementation) external {
         require(msg.sender == admin);
         implementation = newImplementation;
     }


}