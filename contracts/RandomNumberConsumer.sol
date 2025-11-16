pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


/**
为了使用VRF获取随机数，合约需要继承VRFConsumerBaseV2合约，
并在构造函数中初始化VRFCoordinatorV2Interface和Subscription Id。
*/
contract RandomNumberConsumer is VRFConsumerBaseV2{

    //请求随机数需要调用VRFCoordinatorV2Interface接口
    VRFCoordinatorV2Interface COORDINATOR;
    // 申请后的subId
    uint64 subId;

    //存放得到的requestId和随机数
    uint256 public requestId;
    uint256[] public randomWords;

    /**
     * 使用chainlink VRF，构造函数需要继承 VRFConsumerBaseV2
     * 不同链参数填的不一样
     * 具体可以看：https://docs.chain.link/vrf/v2-5/supported-networks#arbitrum-mainnet
     * 网络: Sepolia测试网
     * Chainlink VRF Coordinator 地址: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61
     * LINK 代币地址: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E
     * 50 gwei Key Hash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be
     * Minimum Confirmations 最小确认块数 : 3 （数字大安全性高，一般填12）
     * callbackGasLimit gas限制 : 最大 2,500,000
     * Maximum Random Values 一次可以得到的随机数个数 : 最大 500          
     */
    address vrfCoordinator = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;
    bytes32 keyHash = 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 200_000;
    uint32 numWords = 3;

    constructor(uint64 s_subId) VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subId = s_subId;
    }

    /**
    用户可以调用从VRFCoordinatorV2Interface接口合约中的requestRandomWords函数申请随机数，
    并返回申请标识符requestId。这个申请会传递给VRF合约。
    向VRF合约申请随机数 
    */
    function requestRandomWords() external {
       requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /**
     * VRF合约的回调函数，验证随机数有效之后会自动被调用
     * 消耗随机数的逻辑写在这里
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory s_randomWords) internal override {
        randomWords = s_randomWords;
    }

// // 利用链上伪随机数铸造NFT
function getRandomOnchain() public view returns(uint256){
    /**
    getRandomOnchain()函数利用全局变量
    block.timestamp，msg.sender和blockhash(block.number-1)作为种子来获取随机数.
    首先，block.timestamp，msg.sender和blockhash(block.number-1)这些变量都是公开的，使用者可以预测出用这些种子生成出的随机数，并挑出他们想要的随机数执行合约。
其次，矿工可以操纵blockhash和block.timestamp，使得生成的随机数符合他的利益。
尽管如此，由于这种方法是最便捷的链上随机数生成方法，大量项目方依靠它来生成不安全的随机数，包括知名的项目meebits，loots等。当然，这些项目也无一例外的被攻击了：攻击者可以铸造任何他们想要的稀有NFT，而非随机抽取。
    **/
    //remix 运行blockhash会抱错
    bytes32 randomBytes = keccak256(abi.encodePacked(block.timestamp,msg.sender,blockhash(block.number-1)));
    return uint256(randomBytes);
}


}