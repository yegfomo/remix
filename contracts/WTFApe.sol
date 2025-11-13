pragma solidity ^0.8.21;

import "./ERC721.sol";


//利用ERC721来写一个免费铸造的WTF APE，总量设置为10000，
//只需要重写一下mint()和baseURI()函数即可。由于baseURI()设置的和BAYC一样，元数据会直接获取无聊猿的，类似RRBAYC：
contract WTFAPE is ERC721{

    uint public MAX_APES = 10000;//总量

    //这个 构造函数（constructor） 不是「必须要有」，
    //但如果父合约（这里是 ERC721）需要在部署时接收参数，那你就必须显式写出来并传递过去。
    //如果父类 ERC721 构造函数是 无参的 → 可以不写构造函数，没问题
    constructor(string memory name_,string memory symbol_) ERC721(name_, symbol_){
    }

    //BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
    function _baseURI() internal pure override returns(string memory){
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    // 铸造函数
    function mint(address to,uint tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES,"tokenId out of range");
        _mint(to,tokenId);
    }



}