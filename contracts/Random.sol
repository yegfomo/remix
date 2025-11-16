// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
  Random NFT using Chainlink VRF v2.5 (subscription model)
  - Compiler: 0.8.19
  - Deploy with constructor param: subscriptionId (uint256)
  - Make sure in Chainlink UI / local mock: create subscription, fund it, add this contract as consumer
*/

// 如果你本地有 ERC721.sol，保留下面的本地 import
import "./ERC721.sol";

// 如果没有本地 ERC721，取消下面这一行注释（我推荐使用固定 tag 而不是 master）
// import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/token/ERC721/ERC721.sol";

// Chainlink VRF v2.5 imports (contracts-v1.3.0)
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract Random is ERC721, VRFConsumerBaseV2Plus {
    // NFT 相关
    uint256 public totalSupply = 100; // 总供给
    uint256[100] public ids;         // 用于 pick 随机 tokenId
    uint256 public mintCount;        // 已 mint 数量

    // VRF v2.5 相关参数（可按网络替换）
    // 这里把 coordinator 地址设成你原来用的示例地址（请按你的环境替换为本地 mock / Sepolia 等）
    address public constant VRF_COORDINATOR_ADDRESS = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    // v2.5 gas lane / keyHash (示例值，按网络替换)
    bytes32 public keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint16 public requestConfirmations = 3;
    uint32 public callbackGasLimit = 200_000;
    uint32 public numWords = 3;

    // v2.5 subscription id is uint256
    uint256 public s_subscriptionId;

    // 记录 request => sender
    mapping(uint256 => address) public requestToSender;
    uint256 public lastRequestId;

    // 构造：传入 subscriptionId（uint256）
    //25989255119234791710747870769422431791605681354593841807706830993565620384753
    constructor(uint256 subscriptionId)
        VRFConsumerBaseV2Plus(VRF_COORDINATOR_ADDRESS)
        ERC721("WTF Random", "WTF")
    {
        s_subscriptionId = subscriptionId;
    }

    /* ---------------- 随机 id 算法（你的原实现，仅作小改名） ---------------- */
    function pickRandomUniqueId(uint256 random) private returns (uint256 tokenId) {
        uint256 len = totalSupply - mintCount++;
        require(len > 0, "mint close");
        uint256 randomIndex = random % len;

        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;

        ids[randomIndex] = ids[len - 1] == 0 ? (len - 1) : ids[len - 1];
        ids[len - 1] = 0;
        return tokenId;
    }

    // 链上伪随机（仅作演示，不够安全）
    function getRandomOnchain() public view returns (uint256) {
        bytes32 randomBytes = keccak256(
            abi.encodePacked(blockhash(block.number - 1), msg.sender, block.timestamp)
        );
        return uint256(randomBytes);
    }

    // 使用链上伪随机 mint（不使用 Chainlink）
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain());
        _mint(msg.sender, _tokenId);
    }

    /* ---------------- 使用 Chainlink VRF v2.5 请求随机数 ---------------- */
    // 返回 requestId
    function mintRandomVRF() public returns (uint256 requestId) {
        // 构造 RandomWordsRequest struct（v2.5）
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: s_subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({ nativePayment: false })
            )
        });

        // 使用基类提供的 s_vrfCoordinator 调用（无需自己声明 coordinator）
        requestId = s_vrfCoordinator.requestRandomWords(req);

        requestToSender[requestId] = msg.sender;
        lastRequestId = requestId;
        return requestId;
    }

    // VRF 回调（由 Coordinator 调用）
    // 注意用 calldata 来匹配 v2.5 example 的签名
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address sender = requestToSender[requestId];
        require(sender != address(0), "unknown request");

        uint256 tokenId = pickRandomUniqueId(randomWords[0]);
        _mint(sender, tokenId);

        delete requestToSender[requestId];
    }

    /* 可选：设置 VRF 参数（最好加 onlyOwner 权限） */
    function setVrfParams(bytes32 _keyHash, uint16 _confirmations, uint32 _callbackGasLimit, uint32 _numWords) public {
        keyHash = _keyHash;
        requestConfirmations = _confirmations;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }
}
