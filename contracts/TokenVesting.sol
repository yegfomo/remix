// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

import "./IERC20.sol";



/**
项目方规定线性释放的起始时间、归属期和受益人。
项目方将锁仓的ERC20代币转账给TokenVesting合约。
受益人可以调用release函数，从合约中取出释放的代币。
*/
contract TokenVesting{

    event ERC20Released(address indexed token,uint256 amount);//提币事件

    //状态变量
    //代币地址-》释放数量的映射，记录已经释放的代币
    mapping(address => uint256) public erc20Released;
    address public immutable beneficiary;//受益人地址
    uint256 public immutable start;//起始时间戳
    uint256 public immutable duration;//归属期

     /**
     * @dev 初始化受益人地址，释放周期(秒), 起始时间戳(当前区块链时间戳)
     */
     constructor (address beneficiaryAddress,uint256 durationSeconds){
        require(beneficiaryAddress != address(0),"VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
     }

     /**
     * @dev 受益人提取已释放的代币。
     * 调用vestedAmount()函数计算可提取的代币数量，然后transfer给受益人。
     * 释放 {ERC20Released} 事件.
     */
    function release(address token) public {
         // 调用vestedAmount()函数计算可提取的代币数量
         //虽然释放合约里有钱，但它很笨。
         //它需要你明确告诉它：“请调用 0x424... 这个代币合约 的 transfer 函数，把属于我的那份钱转给我
         uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
         // 更新已释放代币数量   
         erc20Released[token] +=releasable;
         //转币给受益人
          emit ERC20Released(token, releasable);
          //把一个普通的地址（token）“包装”成了一个接口类型（IERC20），
          //告诉编译器：“这个地址是一个 ERC20 代币合约，请允许我调用它的 transfer 函数
          IERC20(token).transfer(beneficiary,releasable);

    }

    /**
     * @dev 根据线性释放公式，计算已经释放的数量。开发者可以通过修改这个函数，自定义释放方式。
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */

     function vestedAmount(address token,uint256 timestamp) public view returns(uint256){
         // 合约里总共收到了多少代币（当前余额 + 已经提取）
         uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
         // 根据线性释放公式，计算已经释放的数量
         if (timestamp < start){
            return 0;
         }else if(timestamp > start + duration){
            return totalAllocation;
         }else{
            return (totalAllocation * (timestamp - start))/duration;
         }

     }







}