// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./IERC1155.sol";

/**
在ERC1155中，每一种代币都有一个id作为唯一标识，每个id对应一种代币。这样，代币种类就可以非同质的在同一个合约里管理了，
并且每种代币都有一个网址uri来存储它的元数据，
类似ERC721的tokenURI。下面是ERC1155的元数据接口合约IERC1155MetadataURI：
**/
/**
 * @dev ERC1155的可选接口，加入了uri()函数查询元数据
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev 返回第`id`种类代币的URI
     */
    function uri(uint256 id) external view returns (string memory);
}