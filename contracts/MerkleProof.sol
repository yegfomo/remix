pragma solidity ^0.8.21;



//我们可以利用网页或者Javascript库merkletreejs来生成Merkle Tree。
//https://lab.miguelmota.com/merkletreejs/example/
//在菜单里选上Keccak-256, hashLeaves和sortPairs选项，然后点击Compute，Merkle Tree就生成好了。Merkle Tree展开为：
//MerkleProof库
library MerkleProof{
     /**
     * @dev 当通过`proof`和`leaf`重建出的`root`与给定的`root`相等时，返回`true`，数据有效。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */

       function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns 通过Merkle树用`leaf`和`proof`计算出`root`. 当重建出的`root`和给定的`root`相同时，`proof`才是有效的。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
     function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0 ;i< proof.length;i++){
            computedHash = _hashPair(computedHash, proof[i]);
        }
         return computedHash;

     }

     // Sorted Pair Hash
     //用keccak256()函数计算非根节点对应的两个子节点的哈希（排序后）。
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

}