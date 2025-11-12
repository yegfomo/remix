// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
IERC165接口合约只声明了一个supportsInterface函数，
输入要查询的interfaceId接口id，若合约实现了该接口id，则返回true
**/
interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    
}