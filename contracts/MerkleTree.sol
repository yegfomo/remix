//利用Merkle Tree发放NFT白名单,链上仅需存储一个root的值，非常节省gas
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./MerkleProof.sol";

/**
一份拥有800个地址的白名单，更新一次所需的gas fee很容易超过1个ETH。
而由于Merkle Tree验证时，leaf和proof可以存在后端，链上仅需存储一个root的值，非常节省gas，
项目方经常用它来发放白名单。很多ERC721标准的NFT和ERC20标准代币的白名单/空投都是利用Merkle Tree发出的，比如optimism的空投。
**/

/**
1.假设白名单是一个地址列表：[0x123..., 0xabc..., 0x456..., 0x789...],
每个地址通过哈希变成 叶子节点,这些叶子节点就是 Merkle Tree 的底层数据。：
leaf0 = keccak256(0x123...)
leaf1 = keccak256(0xabc...)
leaf2 = keccak256(0x456...)
leaf3 = keccak256(0x789...)
2.构建 Merkle Tree:两两组合哈希生成父节点，一直到生成 Merkle Root：
        root
       /    \
   hash0     hash1
   /   \    /   \
leaf0 leaf1 leaf2 leaf3
3.给用户生成 proof,每个叶子都有一个 从叶子到根的哈希路径，就是 proof：
    leaf0 的 proof = [leaf1, hash1]
    leaf2 的 proof = [leaf3, hash0]
    用户 mint 时只需要提交：
    自己的地址（生成 leaf）
    对应的 proof（链下生成）
4.链上验证
    bytes32 leaf = keccak256(abi.encodePacked(account));
    require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
    合约拿 leaf + proof 算出一个 rootCandidate
    对比链上存储的 root：
    相等 → 证明用户在白名单里


**/
contract MarkleTree is ERC721 {
    //constant在编译期就确定值
    //immutable 允许你在 构造函数里赋值，部署后就不可修改
    bytes32 immutable public root; //Merkle树的根
    mapping(address => bool ) public mintedAddress; //记录已经mint的地址

     // 构造函数，初始化NFT合集的名称、代号、Merkle树的根
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

     // 利用Merkle树验证地址并完成mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle检验通过
        require(!mintedAddress[account], "Already minted!"); // 地址没有mint过

        mintedAddress[account] = true; // 记录mint过的地址
        _mint(account, tokenId); // mint
    }

    // 计算Merkle树叶子的哈希值
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}