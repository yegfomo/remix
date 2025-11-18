// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165.sol";

/**
ERC1155接收合约
与ERC721标准类似，为了避免代币被转入黑洞合约，ERC1155要求代币接收合约继承IERC1155Receiver并实现两个接收函数：

 onERC1155Received()：单币转账接收函数，接受ERC1155安全转账safeTransferFrom 需要实现并返回自己的选择器0xf23a6e61。
 onERC1155BatchReceived()：多币转账接收函数，接受ERC1155安全多币转账safeBatchTransferFrom 需要实现并返回自己的选择器0xbc197c81。
*/
interface IERC1155Receiver is IERC165 {

     /**
     * @dev 接受ERC1155安全转账`safeTransferFrom` 
     * 需要返回 0xf23a6e61 或 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data) external returns(bytes4);

     /**
     * @dev 接受ERC1155批量安全转账`safeBatchTransferFrom` 
     * 需要返回 0xbc197c81 或 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address operator,address from,uint256[] calldata ids,uint256[] calldata values,bytes calldata data) external returns(bytes4);

}