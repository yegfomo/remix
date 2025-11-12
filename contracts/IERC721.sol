// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165.sol";


/**
利用tokenId来表示特定的非同质化代币，授权或转账都要明确tokenId；而ERC20只需要明确转账的数额即可。
**/
interface IERC721 is IERC165{
    //事件才能加indexed 用于索引排序
    //在转账时被释放，记录代币的发出地址from，接收地址to和tokenid
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    //批准：授权单个 NFT 的事件，让某人可以转走你的一件 NFT
    event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);
    //批准全部：授权所有 NFT 的事件，让某人可以管理你所有的 NFT（批量授权）
    event ApprovalForAll(address indexed owner,address indexed operator, bool approved);

    //查询某个地址（owner）当前持有的 NFT 数量。
    function balanceOf(address owner) external view returns(uint256 balance);

    //查询某个 NFT（通过它的 tokenId 唯一编号）当前属于哪个地址。
    function ownerOf(uint256 tokenId) external view returns(address owner);

    //   uint256 tokenId,    // NFT ID, bytes calldata data // 附加数据（你这里传的）
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external ;

    //安全转账（如果接收方是合约地址，会要求实现ERC721-Receiver接口）。参数为转出地址from，接收地址to和tokenId
    function safeTransferFrom(address from,address to,uint256 tokenId) external ;

    //普通转账，参数为转出地址from，接收地址to和tokenId。
    function transferFrom(address from,address to,uint256 tokenId) external ;

    //授权另一个地址使用你的NFT。参数为被授权地址approve和tokenId
    function approve(address to, uint256 tokenId) external;

    //将自己持有的该系列NFT批量授权给某个地址operator
    function setApprovalForAll(address operator, bool _approved) external;

    //查询tokenId被批准给了哪个地址。
    function getApproved(uint256 tokenId) external view returns (address operator);

    //查询某个地址 (operator) 是否被另一个地址 (owner) 批量授权管理他所有的 NFT。
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}




