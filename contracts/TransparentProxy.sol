// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
代理合约中的“选择器冲突”，以及如何利用透明代理避免这个问题。透明代理的逻辑简单，通过限制管理员调用逻辑合约解决“选择器冲突”问题。
它也有缺点，每次用户调用函数时，都会多一步是否为管理员的检查，消耗更多gas。但瑕不掩瑜，透明代理仍是大多数项目方选择的方案.
由于代理合约和逻辑合约是两个合约，就算他们之间存在“选择器冲突”也可以正常编译，这可能会导致很严重的安全事故。
举个例子，如果逻辑合约的a函数和代理合约的升级函数的选择器相同，那么管理人就会在调用a函数的时候，
将代理合约升级成一个黑洞合约，后果不堪设想。

目前，有两个可升级合约标准解决了这一问题：透明代理Transparent Proxy和通用可升级代理UUPS。
**/
contract TransparentProxy {
    address implementation; // logic合约地址
    address admin; // 管理员
    string public words; // 字符串，可以通过逻辑合约的函数改变

     // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // 1. 如果有人调用 tryToHACK()，不存在这个函数 -> 触发我
    // 2. 如果有人转账但没有 receive 函数 -> 触发我
    // fallback函数，将调用委托给逻辑合约
    // 不能被admin调用，避免选择器冲突引发意外
    fallback() external payable {
    // 这里通常写代理逻辑，或者直接 revert 报错
       require(msg.sender != admin);
       (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }

}

// 旧逻辑合约
contract Logic1 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器： 0xc2985578
    function foo() public{
        words = "old";
    }
}

// 新逻辑合约
contract Logic2 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器：0xc2985578
    function foo() public{
        words = "new";
    }
}