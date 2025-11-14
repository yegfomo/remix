// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    //让 uint256 类型拥有 Strings 库的功能。
    using Strings for uint256; 
     // Token名称
    string public override name;
    // Token代号
    string public override symbol;
    // tokenId 到 owner address 的持有人映射
    mapping(uint => address) private _owners;
    // address 到 持仓数量 的持仓量映射
    mapping(address => uint) private _balances;
    // tokenID 到 授权地址 的授权映射
    mapping(uint => address) private _tokenApprovals;
    // owner地址 到 operator地址 的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // 错误 无效的接收者
    error ERC721InvalidReceiver(address receiver);

    /**
     * 构造函数，初始化`name` 和`symbol` .
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }




    // 实现IERC165接口supportsInterface
    //告诉外界这个合约支持哪些接口
    //外部调用者（钱包、市场、合约）可以用它判断这个合约是否实现了某个标准接口
    //interfaceId:接口 ID，通常是某个 interface 的 XOR 哈希值
    /**如果外部传进来的 interfaceId 等于：
    ERC721 接口 ID
    ERC165 接口 ID
    ERC721Metadata 接口 ID
    就返回 true，否则返回 false。**/
    //type(IERC721) ： 类型反射语法-》它可以返回与这个类型相关的一些元信息（metadata），常用的就是 .interfaceId
    function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;

    }

    //实现IERC721的balanceOf，利用_balances变量查询owner地址的balance。
    function balanceOf(address owner) external view override returns(uint256 balance){
        //这行代码保证了你传入的 owner 是一个合法地址，而不是空地址。
        //address(0) 在 Ethereum 里通常表示 空地址、未初始化或烧掉的地址
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // 实现IERC721的ownerOf，利用_owners变量查询tokenId的owner。
    function ownerOf(uint256 tokenId) public view override returns(address owner){
        owner =  _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // 实现IERC721的isApprovedForAll，利用_operatorApprovals变量查询owner地址是否将所持NFT批量授权给了operator地址。
    // //查询某个地址 (operator) 是否被另一个地址 (owner) 批量授权管理他所有的 NFT。
    function isApprovedForAll(address owner, address operator) external view override returns (bool){
        return  _operatorApprovals[owner][operator];
    }

    // 实现IERC721的setApprovalForAll，将持有代币全部授权给operator地址。调用_setApprovalForAll函数。
    function setApprovalForAll(address operator, bool approved) external override{
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 实现IERC721的getApproved，利用_tokenApprovals变量查询tokenId的授权地址。
    //查询tokenId被批准给了哪个地址。
    function getApproved(uint256 tokenId) external view override returns (address operator){
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }


    // 授权函数。通过调整_tokenApprovals来授权 to 地址操作 tokenId，同时释放Approval事件。
    function _approve(
        address owner,
        address to,
        uint tokenId) private {
            _tokenApprovals[tokenId] = to;
            emit Approval(owner, to, tokenId);

    }

    // 实现IERC721的approve，将tokenId授权给 to 地址。条件：to不是owner，且msg.sender是owner或授权地址。调用_approve函数。
    function approve(address to, uint256 tokenId) external override {
         address owner = _owners[tokenId];
         //msg.sender → 当前发起交易的人
         //owner → NFT 的真正拥有者
         //调用者要么是 NFT 的 owner，要么是 owner 批量授权的 operator操作员，否则交易失败
         require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    //查询 spender消费地址是否可以使用tokenId（需要是owner或被授权地址）
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    )private view returns (bool) {
         return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }


     /*
     * 转账函数。通过调整_balances和_owner变量将 tokenId 从 from 转账给 to，同时释放Transfer事件。
     * 条件:
     * 1. tokenId 被 from 拥有
     * 2. to 不是0地址
     */

     function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");
        //授权函数。通过调整_tokenApprovals来授权 to 地址操作 tokenId，同时释放Approval事件。
        _approve(owner, address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    // 实现IERC721的transferFrom，非安全转账，不建议使用。调用_transfer函数
    function transferFrom(address from,address to,uint256 tokenId) external override {
        // //查询某个 NFT（通过它的 tokenId 唯一编号）当前属于哪个地址。
        address owner = ownerOf(tokenId);
        require(
            //查询 spender消费地址是否可以使用tokenId（需要是owner或被授权地址）
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }


    /**
     * 安全转账，安全地将 tokenId 代币从 from 转移到 to，会检查合约接收者是否了解 ERC721 协议，以防止代币被永久锁定。调用了_transfer函数和_checkOnERC721Received函数。条件：
     * from 不能是0地址.
     * to 不能是0地址.
     * tokenId 代币必须存在，并且被 from拥有.
     * 如果 to 是智能合约, 他必须支持 IERC721Receiver-onERC721Received.
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }


//函数，用于在 to 为合约的时候调用IERC721Receiver-onERC721Received, 以防 tokenId 被不小心转入黑洞。
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        //.code：Solidity 0.8.x+ 新增的属性，返回 地址对应的字节码
        //判断一个地址是不是合约地址,否则它是一个外部账户（EOA)私钥控制的普通账户 → code.length == 0（EOA（普通钱包地址）没有代码，所以不会触发。）
        if (to.code.length > 0) {
                    try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                        if (retval != IERC721Receiver.onERC721Received.selector) {
                            revert ERC721InvalidReceiver(to);
                        }
                    } catch (bytes memory reason) {
                        if (reason.length == 0) {
                            revert ERC721InvalidReceiver(to);
                        } else {
                            /// @solidity memory-safe-assembly
                            assembly {
                                revert(add(32, reason), mload(reason))
                        }
                    }
            }
        }

    }


     /**
     * 实现IERC721的safeTransferFrom，安全转账，调用了_safeTransfer函数。
     */

     function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        //查询某个 NFT（通过它的 tokenId 唯一编号）当前属于哪个地址
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }


       // safeTransferFrom重载函数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** 
     * 铸造函数。通过调整_balances和_owners变量来铸造tokenId并转账给 to，同时释放Transfer事件。铸造函数。
     * 通过调整_balances和_owners变量来铸造tokenId并转账给 to，同时释放Transfer事件。
     * 这个mint函数所有人都能调用，实际使用需要开发人员重写，加上一些条件。
     * 条件:
     * 1. tokenId尚不存在。
     * 2. to不是0地址.
     * virtual 表示：这个函数是“可被重写”的”，子合约可以用 override 来覆盖它的实现
     */
    function _mint(address to, uint tokenId) internal virtual {
            require(to != address(0), "mint to zero address");
            require(_owners[tokenId] == address(0), "token already minted");

            _balances[to] += 1;
            _owners[tokenId] = to;

            emit Transfer(address(0), to, tokenId);
    }

    // 销毁函数，通过调整_balances和_owners变量来销毁tokenId，同时释放Transfer事件。条件：tokenId存在。
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);

        _balances[owner] -= 1;
        //delete 表示 把映射中指定 key 对应的值重置为默认值
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

     /**
     * 实现IERC721Metadata的tokenURI函数，查询metadata。
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

       /**
     * 计算{tokenURI}的BaseURI，tokenURI就是把baseURI和tokenId拼接在一起，需要开发重写。
     * BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}