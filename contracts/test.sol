pragma solidity ^0.8.4;


contract MyToken {

    uint256 constant _num1 = 10;
    string constant _string = "sasdfxx";
    bytes constant _bytes = "wrssssss";
    address constant _addressx = 0x0000000000000000000000000000000000000000;

    uint256 public immutable _num2 = 10;
    address public immutable _address4;

    



    // 利用constructor初始化immutable变量，因此可以利用
    constructor(){
        _address4 = address(this);
        _num2 = 1118;
    }

    address owner; // 定义owner变量

    // 定义modifier
    modifier onlyOwner {
    require(msg.sender == owner); // 检查调用者是否为owner地址
    _; // 如果是的话，继续运行函数主体；否则报错并revert交易
    }

    function changeOwner(address _newOwner) external onlyOwner{
        owner = _newOwner; // 只有owner地址运行这个函数，并改变owner
    }

//定义_balances变量，记录每个地址的持币数量
mapping (address => uint256) public _balances;
//定义Transfer 事件，记录transfer交易的转账地址，接收地址和转账数量
event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(
        address from,
        address to,
        uint256 amount
     ) external {
        _balances[from] = 10000;
        _balances[from] -= amount;
        _balances[to] += amount; // to地址加上转账数量
        // 释放事件
        emit Transfer(from, to, amount);
    }

    event Log(string msg);

     function hip() public virtual {
        emit Log("Yeye");
    }

    function pop() public virtual{
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye");
    }
}