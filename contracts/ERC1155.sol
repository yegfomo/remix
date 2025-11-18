// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./String.sol";
import "./IERC165.sol";

/**
 * @dev ERC1155多代币标准
 * 见 https://eips.ethereum.org/EIPS/eip-1155
 
 */
contract ERC1155 is IERC165,IERC1155,IERC1155MetadataURI{
    using Strings for uint256;//使用Strings库

    //Token名称
    string public name;
    //Token代号
    string public symbol;
    //代币种类id到账户account到余额balances的映射
    mapping (uint256=> mapping (address=>uint256)) private _balances;
    // address 到 授权地址 的批量授权映射
    mapping(address=>mapping (address=>bool)) private _operatorApprovals;

    /**
     * 构造函数，初始化`name` 和`symbol`, uri_
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    //实现IERC165接口，输入要查询的interfaceId接口id，若合约实现了该接口id，则返回true
    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return
            interfaceId == type(IERC1155).interfaceId || 
            interfaceId == type(IERC1155MetadataURI).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev 持仓查询 实现IERC1155的balanceOf，返回account地址的id种类代币持仓量。
     */
    function balanceOf(address account,uint256 id) public view virtual override returns(uint256){
        require(account != address(0),"ERC1155:address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev 批量持仓查询
     * 要求:
     * - `accounts` 和 `ids` 数组长度相等.
     virtual 关键字用在函数 (function) 或修饰符 (modifier) 上，它的意思是：
“我允许我的子合约（派生合约）来‘重写’(override) 我这个函数。”
     */
     function balanceOfBatch(address[] memory accounts,uint256[] memory ids) public view virtual override returns(uint256[] memory){
         require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
         //在 Solidity 中复杂类型（如数组 []、结构体 struct、字符串 string 或 bytes），你必须明确告诉编译器把它放在哪里。memory (内存).storage (存储
         uint256[] memory batchBalances = new uint256[](accounts.length);
         for (uint256 i = 0; i < accounts.length; i++) {
             batchBalances[i] = balanceOf(accounts[i], ids[i]);
         }
         return batchBalances;
     }

      /**
     * @dev 批量授权，调用者授权operator使用其所有代币（我运行你干事情）
     * 释放{ApprovalForAll}事件
     * 条件：msg.sender != operator
     */
     function setApprovalForAll(address operator,bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
     }

     /**
     * @dev 查询批量授权.
     */
     function isApprovedForAll(address account,address operator) public view virtual override returns(bool){
         return _operatorApprovals[account][operator];
     }

      /**
     * @dev 安全转账，将`amount`单位的`id`种类代币从`from`转账到`to`
     * 释放 {TransferSingle} 事件.
     * 要求:
     * - to 不能是0地址.
     * - from拥有足够的持仓量，且调用者拥有授权
     * - 如果 to 是智能合约, 他必须支持 IERC1155Receiver-onERC1155Received.
     */

     function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) public virtual override {
        // 调用者是持有者或是被授权
        address operator = msg.sender;
        require(from == operator || isApprovedForAll(from,operator),
        "ERC1155: caller is not token owner nor approved"
        );
        //转账地址不能是0地址
        require(to != address(0), "ERC1155: transfer to the zero address");
        // 更新持仓量
        //从 0.8.0 开始：Solidity 默认就是安全的。如果你执行 fromBalance - amount，并且 fromBalance 小于 amount，交易会自动失败 (Revert),这里会消耗gas
        //开发者已经用 require 语句手动确保了 fromBalance 大于或等于 amount。
        //因此，fromBalance - amount 这个减法绝对不可能发生下溢。
        //Solidity 0.8.0 默认的“安全检查”在这里就成了一种浪费，因为它在重复检查一个已经被 require 保证了的条件。
        //为了节省这笔重复检查的 Gas 费用，开发者用 unchecked { ... } 把这个减法包起来，告诉编译器：“别检查了，我前面已经检查过了，我保证这行代码是安全的。帮我省点 Gas 吧。”

        // from地址有足够持仓
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        // 更新持仓量
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
         // 释放事件
        emit TransferSingle(operator, from, to, id, amount);
         // 安全检查
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);    

     }


      /**
     * @dev 批量安全转账，将`amounts`数组单位的`ids`数组种类代币从`from`转账到`to`
     * 释放 {TransferSingle} 事件.
     * 要求:
     * - to 不能是0地址.
     * - from拥有足够的持仓量，且调用者拥有授权
     * - 如果 to 是智能合约, 他必须支持 IERC1155Receiver-onERC1155BatchReceived.
     * - ids和amounts数组长度相等
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // 调用者是持有者或是被授权
         require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        for(uint256 i = 0;i< ids.length;++i){
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >=amount, "ERC1155: insufficient balance for transfer");
            unchecked{
                _balances[id][from] = fromBalance - amount;
                _balances[id][to] +=  amount;
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        // 安全检查
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    

    }

      /**
     * @dev 铸造
     * 释放 {TransferSingle} 事件.

     _mint(to, 10, 50, ...)
     意思： 铸造 50 个 id 为 10 的代币。
     翻译： "给 to 地址 50 瓶治疗药水"。
     在这里，"治疗药水"是半同质化的 (Semi-Fungible)，amount (50) 是它的数量。

     _mint(to, 8888, 1, ...)
     意思： 铸造 1 个 id 为 8888 的代币。，翻译： "给 to 地址 1 件创世神装"。
     在这里，通过将 amount 设置为 1，并保证你再也不铸造 id 为 8888 的代币，这个 id 就事实上变成了 ERC721 那样的“唯一 NFT”。

     amount 本身不是 NFT，你说的对，amount 只是数量。
    但在 ERC1155 这个标准里，amount 和 id 结合在一起，创造了两种可能性：
    SFT (半同质化代币)： 当 amount > 1 时（比如 50 瓶药水）。
    NFT (非同质化代币)： 当 amount = 1 时（比如 1 件神装）。

    那么怎么区分ERC1155中的某类代币是同质化还是非同质化代币呢？其实很简单：如果某个id对应的代币总量为1，
    那么它就是非同质化代币，类似ERC721；如果某个id对应的代币总量大于1，那么他就是同质化代币，因为这些代币都分享同一个id，类似ERC20。

    特性	NFT (非同质化)	SFT (半同质化)
    标准	ERC721 (主流)	ERC1155 (主流)
    比喻	毕加索的画作原作	毕加索画作的限量海报 (共1000张)
    核心	每一个 tokenId 都独一无二	每一个 id 是一个类别
    可互换性	不可 (我的 #8888 号猿猴不等于你的 #9999 号)	可 (我的 1 瓶“治疗药水”等于你的 1 瓶)
    数量	隐含为 1	由 amount 字段明确定义 (可 > 1)
    _mint 函数	_mint(to, tokenId)	_mint(to, id, amount, ...)
     */
    function _mint( 
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        address operator = msg.sender;
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }


     /**
     * @dev 批量铸造
     * 释放 {TransferBatch} 事件.
     */

     function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = msg.sender;
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev 销毁
     */

     function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        emit TransferSingle(operator, from, address(0), id, amount);
    }


    /**
    批量销毁
    */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
         require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
         address operator = msg.sender;
         for (uint256 i = 0;i<ids.length;i++){
             uint256 fromBalance = _balances[ids[i]][from];
             require(fromBalance >= amounts[i], "ERC1155: burn amount exceeds balance");
             unchecked {
             _balances[ids[i]][from] = fromBalance - amounts[i];
        }

        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }


     // @dev ERC1155的安全转账检查
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }


    // @dev ERC1155的批量安全转账检查
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }


    /**
     * @dev 返回ERC1155的id种类代币的uri，存储metadata，类似ERC721的tokenURI.

     是一个内部（internal）辅助函数，它被用来设置和返回 URL 的“前缀”部分
     这整段代码的作用是，OpenSea 或其他钱包来“询问” id 为 8888 的代币长什么样时，这个 uri 函数会智能地回答一个完整的 URL：
    "https://api.mygame.com/token/8888"
    然后 OpenSea 就会去访问这个 URL，下载它返回的 JSON 文件，从而知道这个 NFT 叫什么名字、长什么图片、有什么属性。
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        //abi.encodePacked(...): 这是 Solidity 中最高效的字符串拼接方法。
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }


      /**
     * 计算{uri}的BaseURI，uri就是把baseURI和tokenId拼接在一起，需要开发重写.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }



}