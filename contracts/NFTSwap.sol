pragma solidity ^0.8.4;

import "./IERC721Receiver.sol";
import "./IERC721.sol";

//去中心化NFT交易所
//ERC721的安全转账函数会检查接收合约是否实现了onERC721Received()函数
contract NFTSwap is IERC721Receiver {
    /**
    如果合约能正确返回 selector（0x150b7a02），表示：我知道你给我转 NFT，我能处理。
    一个合约如果没有这个函数，NFT 无法通过 safeTransferFrom 转进去
    有这个函数，就能通过 safeTransferFrom 转进去
    IERC721Receiver 只是防呆机制，防止 NFT 被锁死。它不是安全认证，也不是信任标识
    */
    function onERC721Received(address operator,address from,uint tokenId,bytes calldata data) external override returns (bytes4){
        //IERC721Receiver.onERC721Received.selector 是一个固定的 4 字节（bytes4）值
        //它不是函数，不是变量，而是 函数选择器（function selector），用于唯一标识一个函数。
        //函数选择器 = keccak256("函数签名") 的前 4 个字节
        //函数签名：onERC721Received(address,address,uint256,bytes)
        //计算方式：keccak256("onERC721Received(address,address,uint256,bytes)") = 0x150b7a02... (很长的一串).取前4字节 → 0x150b7a02
        //这就是 selector。
        return IERC721Receiver.onERC721Received.selector;
    }


    //定义四个事件
    //对应卖家挂单
    event List(address indexed seller,address indexed nftAddr,uint256 indexed tokenId,uint256 price);

    //对应卖家撤单
    event Revoke(address indexed seller,address indexed nftAddr,uint256 indexed tokenId);

    //对应卖家修改价格
    event Update(address indexed seller,address indexed nftAddr,uint256 indexed tokenId,uint256 newPrice);

    //对应买家购买
    event Purchase(address indexed buyer,address indexed nftAddr,uint256 indexed tokenId, uint256 price);

    //NFT订单抽象为Order结构体，包含挂单价格price和持有人owner信息。
    struct Order{
        address owner;
        uint256 price;
    }

    //nftList映射记录了订单是对应的NFT系列（合约地址）和tokenId信息。
    //nft -> tokenId -> 具体信息(所有者，金额)
    mapping(address=>mapping(uint256=>Order)) public nftList;

    //用户使用ETH购买NFT。因此，合约需要实现fallback()函数来接收ETH
    //回退函数：用来处理没有匹配到任何函数调用时的情况。当有人向你的合约发起交易，但调用的函数不存在时，Solidity 会自动执行 fallback()。
    //用户发来的 ETH 会直接进入合约余额里（在遇到意料外的调用时，不会意外报错或拒绝服务。它不是为了保护用户资金，而是为了让你的合约在异常情况下依然正常运行。）
    fallback() external payable{}


    //交易
    //挂单list()：卖家创建NFT并创建订单，并释放List事件。参数为NFT合约地址_nftAddr，NFT对应的_tokenId，挂单价格_price（注意：单位是wei ）。
    //成功后，NFT会从卖家转到NFTSwap合约中。

    function list(address _nftAddr,uint256 _tokenId, uint256 _price) public {
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        //先看NFT合约是否得到了授权
        //当下面的safeTransferFrom 成功执行时，NFT 从 msg.sender 转到了交易所合约 (address(this))
        //当 NFT 转移所有权时，tokenId 的 现有批准 (approval) 会自动 清空
        require(_nft.getApproved(_tokenId) == address(this),"Need Approval");
        require(_price > 0); // 价格大于0
        //获取引用，设置NFT持有人和价格
        Order storage _order = nftList[_nftAddr][_tokenId];
        //msg.sender-当前调用者的地址,_order.owner 记录的是谁上架了这件 NFT,也就是 NFT 的原持有人
        _order.owner = msg.sender;
        _order.price = _price;
        // 将NFT转账到当前合约交易所( address from,address to,uint tokenId,)
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // 释放List事件
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    //撤单revoke()：卖家撤回挂单，并释放Revoke事件。参数为NFT合约地址_nftAddr，NFT对应的_tokenId。成功后，NFT会从NFTSwap合约转回卖家。
    function revoke(address _nftAddr,uint256 _tokenId) public {
        Order storage _order =nftList[_nftAddr][_tokenId];// 取得Order     
        require( _order.owner == msg.sender, "Not Owner");// 必须由持有人发起

        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中

        //将NFT转给卖家
        _nft.safeTransferFrom(address(this),msg.sender,_tokenId);
        delete nftList[_nftAddr][_tokenId];
         // 释放Revoke事件
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    //修改价格update()：卖家修改NFT订单价格，并释放Update事件。
    //参数为NFT合约地址_nftAddr，NFT对应的_tokenId，更新后的挂单价格_newPrice（注意：单位是wei ）。
    function update(address _nftAddr,uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT价格大于0
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中

        _order.price = _newPrice; // 更新价格      
         // 释放Update事件
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    // 购买: 买家购买NFT，合约为_nftAddr，tokenId为_tokenId，调用函数时要附带ETH
    function purchase(address _nftAddr,uint256 _tokenId) public payable {
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order
        require(_order.price > 0, "Invalid Price"); // NFT价格大于0
        require(msg.value >= _order.price, "Increase price"); // 购买价格大于标价
        // 将NFT转给买家(因为这里NFT已经在交易所了，所有from就是address(this))
        _nft.safeTransferFrom(address(this),msg.sender,_tokenId);
        // 将ETH转给卖家
        payable(_order.owner).transfer(_order.price);
        // 多余ETH给买家退款
        if (msg.value > _order.price){
             payable(msg.sender).transfer(msg.value - _order.price);
        }
         // 释放Purchase事件
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);

        delete nftList[_nftAddr][_tokenId]; // 删除order
    }


}