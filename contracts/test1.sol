pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

// 通过文件相对位置import
//import './Yeye.sol';
// 通过`全局符号`导入特定的合约
//import {Yeye} from './Yeye.sol';
// 通过网址引用
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// 引用OpenZeppelin合约
import '@openzeppelin/contracts/access/Ownable.sol';


contract Test1 {

    // 利用using for指令
    using Strings for uint256;
    function getString(uint256 num) public pure returns (string memory result) {
        result = num.toHexString();
    }


    // 直接通过库合约名调用
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }


    // 定义事件
event Received(address Sender, uint Value);

// 接收ETH时释放Received事件
receive() external payable {
    emit Received(msg.sender, msg.value);
}

event fallbackCalled(address Sender, uint Value, bytes Data);

// fallback 填了calldata但是没有找见函数，或者没有填calldata也没有received
fallback() external payable{
    emit fallbackCalled(msg.sender, msg.value, msg.data);
}


    



}