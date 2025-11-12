// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";


//向多个地址转账ERC20代币：你必须在名单里，用 cryptographic proof（加密证明）验证，通过后才能领
contract Airdrop{

    mapping(address=>uint) failTransferList;

    /// @notice 向多个地址转账ERC20代币，使用前需要先授权
    /// @param _token 转账的ERC20代币地址
    /// @param _addresses 空投地址数组
    /// @param _amounts 代币数量数组（每个地址的空投数量）
    function multiTransferToken(address _token,address[] calldata _addresses, uint256[] calldata _amounts) external {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length,"length not equal");
        //计算总额
        uint sum = getSum(_amounts);
        //判断是否当前调用此合约的人有当前合约对应的钱数
        IERC20 token = IERC20(_token);
        //第一个参数是代币持有人,第二个参数是被授权的人
        //用户（msg.sender）想通过这个“空投合约”把代币分发给别人。
        //空投合约本身没有这些代币，用户给他提供了之后，空投合约检查是否获得授权：
        require(token.allowance(msg.sender,address(this)) >= sum,"no enough allowance");
        //如果有授权,发送空头
        for (uint i = 0;i<_addresses.length;i++){
            token.transferFrom(msg.sender,_addresses[i],_amounts[i]);
        }
        

    }

    function getSum(uint256[] calldata _amounts) internal pure returns(uint sum){
        for(uint i=0;i<_amounts.length;i++){
            sum+=_amounts[i];
        }

    }


    //向多个地址转账ETH
    function multiTransferETH(address[] calldata  _addresses,uint[] calldata _amounts) public payable{
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length,"length not equal");
         uint _amountSum = getSum(_amounts); // 计算空投ETH总量
          // 检查转入ETH等于空投总量
        require(msg.value == _amountSum, "Transfer amount error");
         // for循环，利用transfer函数发送ETH
         for (uint256 i = 0; i < _addresses.length; i++) {
             (bool success, ) = _addresses[i].call{value:_amounts[i]}("");
              if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
         }
         


    }


     // 给空投失败提供主动操作机会
    function withdrawFromFailList(address _to) public {
        uint failAmount = failTransferList[msg.sender];
        require(failAmount > 0, "You are not in failed list");
        failTransferList[msg.sender] = 0;
        //Solidity/以太坊的规则：外部调用只是触发合约执行，合约自己才是真正的 ETH 转出方
        //data：可选调用数据，这里是 ""，表示不调用任何函数，只发送 ETH
        //recipient（这里是 _to）：接收 ETH 的地址
        //调用者是谁？ → 是当前合约
        //合约自己把 failAmount ETH 发给 _to
        (bool success, ) = _to.call{value: failAmount}("");
        require(success, "Fail withdraw");
    }


}