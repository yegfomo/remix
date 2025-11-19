// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 分账合约 
 * @dev 这个合约会把收到的ETH按事先定好的份额分给几个账户。收到ETH会存在分账合约中，需要每个受益人调用release()函数来领取。
 */
contract PaymentSplit{
    event PayeeAdded(address account,uint256 shares);// 增加受益人事件
    event PaymentReleased(address to,uint256 amount);// 受益人提款事件
    event PaymentReceived(address from, uint256 amount); // 合约收款事件

    uint256 public totalShares;//总份额
    uint256 public totalReleased;//总支付

    mapping (address => uint256) public shares;//每个受益人的份额
    mapping (address => uint256) public released;//每个受益人已经支付的金额
    address[] public payees; // 受益人数组


    // 受益人数组 和 每个受益人的份额
    constructor(address[] memory _payees,uint256[] memory _shares)  payable {
        // 检查_payees和_shares数组长度相同，且不为0
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // 调用_addPayee，更新受益人地址payees、受益人份额shares和总份额totalShares
        for(uint256 i = 0;i<_payees.length;i++){
            _addPayee(_payees[i],_shares[i]);
        }
    }

     /**
     * @dev 新增受益人_account以及对应的份额_accountShares。只能在构造器中被调用，不能修改。
     */
     function _addPayee(address _account,uint256 _accountShares) private {
        // 检查_account不为0地址
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // 检查_accountShares不为0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // 检查_account不重复
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // 更新payees，shares和totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // 释放增加受益人事件
        emit PayeeAdded(_account, _accountShares);
    }

     /**
     * @dev 回调函数，收到ETH释放PaymentReceived事件
     */

    receive() external payable virtual  {
        emit PaymentReceived(msg.sender, msg.value);
    }

     /**
     * @dev 为有效受益人地址_account分帐，相应的ETH直接发送到受益人地址。任何人都可以触发这个函数，但钱会打给account地址。
     * 调用了releasable()函数。
     */
    function release(address payable _account) public virtual {
        // account必须是有效受益人
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // 计算account应得的eth
        uint256 payment = releaseable(_account);
        // 应得的eth不能为0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // 更新总支付totalReleased和支付给每个受益人的金额released
        totalReleased += payment;
        released[_account] += payment;
        // 转账
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

     /**
     * @dev 计算一个账户能够领取的eth。
     * 调用了pendingPayment()函数。
     */
     function releaseable(address _account) public view returns(uint256){
        //公司总收入
        //totalReleased--总支付
        uint256 totalReceived = address(this).balance + totalReleased;
        // 调用_pendingPayment计算account应得的ETH
        return pendingPayment(_account, totalReceived, released[_account]);
     }

    /**
     * @dev 根据受益人地址`_account`, 分账合约总收入`_totalReceived`和该地址已领取的钱`_alreadyReleased`，计算该受益人现在应分的`ETH`。
     */
     function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns(uint256){
         // account应得的ETH = 总应得ETH - 已领到的ETH
         //_totalReceived (公司总收入): 公司这个月赚了 $1000
         //totalShares (总股份): 50 + 30 + 20 = 100 股
         //Alice：持有 50 股,这行代码算出 Alice 总共应得 $500。
          //--假设 Alice 上周已经领走了 $200。

          //在 Solidity 中处理分红或比例计算时，为了最大限度地保留精度，你必须始终坚持**“先乘后除”**的顺序。
        //你刚才看的代码 (_totalReceived * shares[_account]) / totalShares 正是遵循了这个准则。
         return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    
    
}
