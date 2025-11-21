// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultisigWallet{
    //ExecutionSuccess和ExecutionFailure.
    //分别在交易成功和失败时释放，参数为交易哈希。
    event ExecutionSuccess(bytes32 txHash);
    event ExecutionFailure(bytes32 txHash);

    address[] public owners;//多签持有人数组
    mapping(address=>bool) public isOwner; //记录一个地址是否为多签持有人
    uint256 public ownerCount;//多签持有人数量
    uint256 public threshold;//多签执行门槛，交易至少有n个多签后才能被执行
    uint256 public nonce;//初始为0，随着多签合约每笔成功执行的交易递增的值，可以防止签名重放攻击


     receive() external payable {}

    //构造函数：调用_setupOwners()，
    //初始化和多签持有人和执行门槛相关的变量
    constructor(address[] memory _owners,uint256 _threshold){
        _setupOwners(_owners, _threshold);
    }

    /// @dev 初始化owners, isOwner, ownerCount,threshold 
    /// @param _owners: 多签持有人数组
    /// @param _threshold: 多签执行门槛，至少有几个多签人签署了交易
    function _setupOwners(address[] memory _owners,uint256 _threshold) internal {
        // threshold没被初始化过
        require(threshold == 0,"WTF5000");
        //多签执行门槛小于或等于多签人数
        require(_threshold <= _owners.length,"WTF5001");
        //多签执行门槛至少为1
        require(_threshold >= 1,"WTF5002");

        for(uint i =0;i<_owners.length; i++){
            address owner = _owners[i];
            //多签人不能为0地址，与本合约地址不能重复,并且一个人不能签名多次
            require(owner != address(0) && owner!=address(this) && !isOwner[owner], "WTF5003");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev 在收集足够的多签签名后，执行交易
    /// @param to 目标合约地址
    /// @param value msg.value，支付的以太坊
    /// @param data calldata
    /// @param signatures 打包的签名，对应的多签地址由小到达，方便检查。 ({bytes32 r}{bytes32 s}{uint8 v}) (第一个多签的签名, 第二个多签的签名 ... )

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success){
        // 编码交易数据，计算哈希
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++; //增加nonce
        checkSignatures(txHash, signatures);//检查签名
        // 利用call执行交易，并获取交易结果
        (success, ) = to.call{value: value}(data);
        require(success , "WTF5004");
         if (success) emit ExecutionSuccess(txHash);
         else emit ExecutionFailure(txHash);
    }


    ///  编码交易数据
    /// @param to 目标合约地址
    /// @param value msg.value，支付的以太坊
    /// @param data calldata
    /// @param _nonce 交易的nonce.
    /// @param chainid 链id
    /// @return 交易哈希bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid) public pure returns(bytes32){
            //无论里面的 data 有多大，经过 keccak256 后，永远是 32 字节
            //abi.encode(...) 是 Solidity 的内置函数，它会将括号内的所有参数按照 EVM 的 ABI 规范进行编码，生成一个 bytes 类型的字节串
            bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                    )
            );
        return safeTxHash;
    }

    /**
    * 检查签名和交易数据是否对应。如果是无效签名，交易会revert
    * @param dataHash 交易数据哈希
    * @param signatures 几个多签签名打包在一起
    */
    function checkSignatures(bytes32 dataHash,bytes memory signatures) public view{
        //读取多签执行门槛
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");
         // 检查签名长度足够长
         require(signatures.length >= _threshold * 65, "WTF5006");
         // 通过一个循环，检查收集的签名是否有效
            // 大概思路：
            // 1. 用ecdsa先验证签名是否有效
            // 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
            // 3. 利用 isOwner[currentOwner] 确定签名者为多签持有人
            address lastOwner = address(0); 
            address currentOwner;
            uint8 v;
            bytes32 r;
            bytes32 s;
            uint256 i;
             for (i = 0; i < _threshold; i++) {
                (v, r, s) = signatureSplit(signatures, i);
                /**
                    1.\x19Ethereum Signed Message:\n32: 这是以太坊签名的标准前缀。
                    它的存在是为了防止签名滥用。如果用户在以太坊网络外（比如其他非区块链系统）签了一个名，
                    或者是签了一个普通的交易，这个前缀能保证它们生成的哈希值完全不同，
                    防止黑客把别的签名拿到这里来“重放”
                    2.dataHash:32 字节哈希（通常是 keccak256(abi.encode(...)) 算出来的 structHash）。
                    3.ecrecover: 这是一个数学反向运算。输入：消息哈希 + 签名数据(v, r, s)。输出：签名者的钱包地址。
                        签名过程（正向）： 已知 私钥 + 消息 -> 算出 $r, s$。
                        恢复过程（ecrecover）： 已知 $r, s$ + 消息 -> 反解出 公钥 ($P$)。
                */
                  currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
                 require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
                  lastOwner = currentOwner;
             }

    }

    /// 将单个签名从打包的签名分离出来
    /// @param signatures 打包签名
    /// @param pos 要读取的多签index.
    /**
        signatures 是一个 bytes 类型的数组。在内存中，它的布局如下：
        前 32 字节 (0x00-0x20): 存放数组长度。
        之后的数据: 实际的签名内容。
        每个签名长度为 65 字节 (32字节 r + 32字节 s + 1字节 v)。
    */
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns(
        uint8 v,
        bytes32 r,
        bytes32 s
    ){
        //从一串紧密排列的二进制签名数据中，“切”出第 N 个签名的 r, s, v 三个值。
         // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
         assembly {
                //算当前要读取的签名相对于数据区起始位置的偏移量。
               let signaturePos := mul(0x41, pos)
               /**
                signatures: 指向内存中 bytes 结构的起始地址（长度字段的位置）。
                add(..., 0x20): 跳过前 32 字节的长度字段，指向实际数据的开始。
                add(..., signaturePos): 移动到当前签名的 r 值开始处。
                mload(...): 读取接下来的 32 字节。
               */
                r := mload(add(signatures, add(signaturePos, 0x20)))
                /**
                0x40 (十进制 64): 为什么是 64？
                0x20 (跳过长度) + 0x20 (跳过刚才读完的 r) = 0x40。
                */
                s := mload(add(signatures, add(signaturePos, 0x40)))
                /**
                and(..., 0xff)：把前面 31 个字节（属于 s 的一部分和一些填充）全部抹零，只保留最后 1 个字节。
                Solidity 高级优化中常见的技巧，目的是通过调整读取偏移量，让目标字节自然落在最低位，从而节省 Gas。
                */
                v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
    }
}
        

}