// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
IERC721Receiver 是一个标准接口，用于保证 NFT 被安全地转到一个合约里。只有实现了 onERC721Received 的合约才能接收 NFT。
**/
interface IERC721Receiver {
    /**
    什么时候会调用这个函数：当你做 safeTransferFrom 时：
    如果 to 是一个合约：ERC721 合约用 to.code.length 检查是不是合约
    如果是合约 → 必须调用 onERC721Received
    对方合约必须返回 这个固定的 selector：
    1.这个方法只是告诉链：“我是一个能接收 NFT 的合约。
    2. 只有合约地址才会触发这个验证。
    3. 合约必须返回正确 selector，否则 NFT 智能合约会拒绝发送（保护 NFT 避免被锁死）
    if (to.code.length > 0) {   // 对象是合约
    retval = IERC721Receiver(to).onERC721Received(...)
    if (retval != selector) revert "Invalid receiver";
}
    **/
    function onERC721Received(address operator,address from,uint tokenId,bytes calldata data) external returns (bytes4);
}