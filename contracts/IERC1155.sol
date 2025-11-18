pragma solidity ^0.8.4;

import "./IERC165.sol";

/**
IERC1155接口合约抽象了EIP1155需要实现的功能，其中包含4个事件和6个函数。
与ERC721不同，因为ERC1155包含多类代币，它实现了批量转账和批量余额查询，一次操作多种代币。

与ERC721标准类似，为了避免代币被转入黑洞合约，ERC1155要求代币接收合约继承IERC1155Receiver并实现两个接收函数：
onERC1155Received()：单币转账接收函数，接受ERC1155安全转账safeTransferFrom 需要实现并返回自己的选择器0xf23a6e61。
 onERC1155BatchReceived()：多币转账接收函数，接受ERC1155安全多币转账safeBatchTransferFrom 需要实现并返回自己的选择器0xbc197c81。
*/
interface IERC1155 is IERC165{

     /**
     * @dev 单类代币转账事件
     * 当`value`个`id`种类的代币被`operator`从`from`转账到`to`时释放.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev 批量代币转账事件
     * ids和values为转账的代币种类和数量数组
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev 批量授权事件
     * 当`account`将所有代币授权给`operator`时释放
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved); 

    /**
     * @dev 当`id`种类的代币的URI发生变化时释放，`value`为新的URI
     */
    event URI(string value, uint256 indexed id);

     /**
     * @dev 持仓查询，返回`account`拥有的`id`种类的代币的持仓量
     */
    function balanceOf(address account,uint256 id) external view returns(uint256);

    /**
     * 批量持仓查询，‘accounts’ 和 ‘ids’数组的长度要相等
     */
    function balanceOfBatch(address[] calldata accounts,uint256[] calldata ids) external view returns (uint256[] memory);

    /**
    * 批量授权，将调用者的代币授权给'operator'地址
    */
    function setApprovalForAll(address operator,bool approved) external ;

     /**
     * @dev 批量授权查询，如果授权地址`operator`被`account`授权，则返回`true`
     * 见 {setApprovalForAll}函数.
     */
    function isApprovedForAll(address account,address operator) external view returns(bool);

    /**
     * @dev 安全转账，将`amount`单位`id`种类的代币从`from`转账给`to`.
     * 释放{TransferSingle}事件.
     * 要求:
     * - 如果调用者不是`from`地址而是授权地址，则需要得到`from`的授权
     * - `from`地址必须有足够的持仓
     * - 如果接收方是合约，需要实现`IERC1155Receiver`的`onERC1155Received`方法，并返回相应的值
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external ;

      /**
     * @dev 批量安全转账
     * 释放{TransferBatch}事件
     * 要求：
     * - `ids`和`amounts`长度相等
     * - 如果接收方是合约，需要实现`IERC1155Receiver`的`onERC1155BatchReceived`方法，并返回相应的值
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external ;



}
