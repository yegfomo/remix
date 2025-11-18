// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

/**
我们魔改下ERC721标准的无聊猿BAYC，创建一个免费铸造的BAYC1155。
我们修改_baseURI()函数，使得BAYC1155的uri和BAYC的tokenURI一样。这样，BAYC1155元数据会与无聊猿的相同：
*/
import "./ERC1155.sol";

contract BAYC1155 is ERC1155{
    //声明了一个**“常量” (Constant)*
    uint256 constant MAX_ID = 1000;
    constructor() ERC1155("BAYC1155","BAYC1155"){   
    }

    //BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

     // 铸造函数
    function mint(address to,uint256 id,uint256 amount) external {
        //id不能超10000
         require(id < MAX_ID, "id overflow");
         _mint(to,id,amount,"");
    }

    // 批量铸造函数
     function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        // id 不能超过10,000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
     }
}