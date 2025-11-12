pragma solidity ^0.8.4;
import "./test.sol";

contract BB is MyToken{

     function hip() public virtual override{
        emit Log("Baba");
    }

    function pop() public virtual override{
        emit Log("Baba");
    }

      function baba() public virtual{
        emit Log("Baba");
    }

}