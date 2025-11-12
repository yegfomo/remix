// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
abi.encode	✅	标准对齐，可直接 decode
abi.encodePacked	❌	紧凑编码，无 padding，无法 decode
abi.encodeWithSignature	✅（跳过前4字节）	前 4 字节是函数 selector
abi.encodeWithSelector	✅（跳过前4字节）	同上
**/
contract ABIEncode{
    uint x = 10;
    address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    string name = "0xAA";
    uint[2] array = [5, 6];

    function encode() public view returns (bytes memory result){
        result = abi.encode(x, addr, name, array);
    }

    function encodePacked() public view returns (bytes memory result){
        result = abi.encodePacked(x, addr, name, array);
    }

    function encodeWithSignature() public view returns (bytes memory result){
        result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])",x, addr, name, array);
    }

    function encodeWithSelector() public view returns (bytes memory result){
        result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")),x, addr, name, array);
    }



    function decode(bytes memory data) public pure returns(uint dx,address daddr ,string memory dname,uint[2] memory darray){
        (dx,daddr,dname,darray) = abi.decode(data,(uint,address,string,uint[2]));

    }

}