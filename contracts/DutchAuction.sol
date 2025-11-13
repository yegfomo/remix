// SPDX-License-Identifier: MIT
//荷兰拍卖，基于Azuki的代码简化而成。DucthAuction合约继承了之前介绍的ERC721和Ownable合约
//其中共有9个函数
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/ERC721.sol";

contract DutchAuction is Ownable , ERC721{
    uint public constant COLLECTION_SIZE  = 1000; // NFT总数
    uint public constant AUCTION_START_PRICE = 1 ether; // 起拍价(最高价)
    uint public constant AUCTION_END_PRICE = 0.1 ether; // 结束价(最低价/地板价)
    uint public constant AUCTION_TIME = 10 minutes; // 拍卖时间，为了测试方便设为10分钟
    uint public constant AUCTION_DROP_INTERVAL = 1 minutes; // 每过多久时间，价格衰减一次
    //计算总共降多少： AUCTION_START_PRICE - AUCTION_END_PRICE
    //计算总共会降几次：AUCTION_TIME / AUCTION_DROP_INTERVAL
    uint public constant AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
    (AUCTION_TIME / AUCTION_DROP_INTERVAL); // 每次价格衰减步长


    uint public auctionStartTime; // 拍卖开始时间戳
    string private _baseTokenURI;   // metadata URI
    uint[] private _allTokens; // 记录所有存在的tokenId


    //设定拍卖起始时间：我们在构造函数中会声明当前区块时间为起始时间，项目方也可以通过setAuctionStartTime()函数来调整
    constructor() Ownable(msg.sender) ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        //当前区块时间
        auctionStartTime = block.timestamp;
    }

      // auctionStartTime setter函数，onlyOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    /**
    获取拍卖实时价格：getAuctionPrice()函数通过当前区块时间以及拍卖相关的状态变量来计算实时拍卖价格。
    当block.timestamp小于起始时间，价格为最高价AUCTION_START_PRICE；
    当block.timestamp大于结束时间，价格为最低价AUCTION_END_PRICE；
    当block.timestamp处于两者之间时，则计算出当前的衰减价格。
    **/
    function getAuctionPrice() public view returns(uint){
        if(block.timestamp < auctionStartTime){
            return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME){
            return AUCTION_END_PRICE;
        }else {
            uint steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE -  (steps * AUCTION_DROP_PER_STEP);
        }

    }

    /**
     * ERC721Enumerable中totalSupply函数的实现
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

     /**
     * Private函数，在_allTokens中添加一个新的token
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

    //用户拍卖并铸造NFT：用户通过调用auctionMint()函数，支付ETH参加荷兰拍卖并铸造NFT。
    //quantity-想要铸造多少个 NFT
    function auctionMint(uint256 quantity) external payable {
        //拍卖开始时间
        uint256 _saleStartTime = uint256(auctionStartTime); //类型转换赋值，建立local变量，减少gas花费
        require(_saleStartTime !=0 && block.timestamp > _saleStartTime,"sale has not started yet");
        //检查是否超过NFT上限
        require(totalSupply() + quantity <= COLLECTION_SIZE, "not enough remaining reserved for auction to support desired mint amount");
         uint256 totalCost = getAuctionPrice() * quantity; // 计算mint成本
        require(totalCost  <= msg.value, "not enough ETH to mint desired amount"); //检查用户的钱eth是否足够
        //开始发放（抽盲盒）
        for(uint i = 0 ; i<quantity ; i++) {
             uint256 mintIndex = totalSupply();
            _mint(msg.sender,mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }

        if(msg.value > totalCost){
            payable(msg.sender).transfer(msg.value-totalCost);////注意一下这里是否有重入的风险
        }
    }


    //项目方取出筹集的ETH：项目方可以通过withdrawMoney()函数提走拍卖筹集的ETH。
    // 提款函数，onlyOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}(""); // call函数的调用方式详见第22讲
        require(success, "Transfer failed.");
    }








}