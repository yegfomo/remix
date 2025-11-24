// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC4626} from "./IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
构造函数初始化基础资产的合约地址，金库份额的代币名称和符号。注意，金库份额的代币名称和符号要和基础资产有关联，比如基础资产叫 WTF，金库份额最好叫 vWTF。
存款时，当用户向金库存 x 单位的基础资产，会铸造 x 单位（等量）的金库份额。
取款时，当用户销毁 x 单位的金库份额，会提取 x 单位（等量）的基础资产。
*/

/**
 * @dev ERC4626 "代币化金库标准"合约，仅供教学使用，不要用于生产
 */

 contract ERC4626 is ERC20, IERC4626 {
    /*//////////////////////////////////////////////////////////////
                    状态变量
    //////////////////////////////////////////////////////////////*/
    ERC20 private immutable _asset; // 这是一个内部状态变量（ IERC20 类型），存储了该合约所管理的代币合约实例。
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;//资产
        _decimals = asset_.decimals();//资产小数，金库份额（Share）的精度通常需要跟底层资产（Asset）保持一致。

    }

     /** @dev See {IERC4626-asset}. 返回管理的ERC20 代币地址*/
    function asset() public view virtual override returns (address) {
        return address(_asset);//将这个接口实例强制转换为 address 类型返回。
    }

    /**
     * See {IERC20Metadata-decimals}.
     override(IERC20Metadata, ERC20) —— 多重继承冲突解决，全部重写
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                        存款/提款逻辑
    //////////////////////////////////////////////////////////////*/
    //存款（关键前提：授权 (Approve)，Approve: 用户告诉 USDC 合约：“我允许 address(this) 这个合约动用我 100 块钱。”）
    //transferFrom: 你的合约执行这行代码时，USDC 合约会检查：“这个用户授权给你了吗？”
    function deposit(uint256 assets,address receiver) public virtual returns (uint256 shares){
        // 利用 previewDeposit() 计算将获得的金库份额
        shares = previewDeposit(assets);
        // 先 transfer 后 mint，防止重入
        //把用户钱包里的钱（代币），“拉”到了当前这个合约里
        //transfer(to, amount): 是**推（Push）**模式。
            //场景：我要给你转账。我主动调用代币合约，把钱推给你。
        //transferFrom(from, to, amount): 是**拉（Pull）**模式。
            //场景：你去超市刷卡。超市的 POS 机（当前合约） 发起指令，从你的银行卡（msg.sender） 里把钱拉到超市账户里。
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        // 释放 Deposit 事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
    deposit (存款)	我付 100 USDC (assets)	能买多少份额算多少	加油站加油：“加 200 块钱的油。” (加多少升随缘)
    mint (铸造)	我要 10 份 (shares)	需要扣多少 USDC 你来算	买股票：“我要买 100 股。” (扣多少钱按市价算)
    */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        // 利用 previewMint() 计算需要存款的基础资产数额
        assets = previewMint(shares);
        // 先 transfer 后 mint，防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        // 释放 Deposit 事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    //取款
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
        ) public virtual returns (uint256 shares) {
        // 利用 previewWithdraw() 计算将销毁的金库份额
        shares = previewWithdraw(assets);
        // 如果调用者不是 owner，则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先销毁后 transfer，防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

         // 释放 Withdraw 事件
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

    }

    // 赎回
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // 利用 previewRedeem() 计算能赎回的基础资产数额
        assets = previewRedeem(shares);

        // 如果调用者不是 owner，则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先销毁后 transfer，防止重入
         _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // 释放 Withdraw 事件       
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

     /*//////////////////////////////////////////////////////////////
                            会计逻辑
    //////////////////////////////////////////////////////////////*/
    function totalAssets() public view virtual returns (uint256){
        // 返回合约中基础资产持仓（直接去erc20查询当前地址有多少钱，钱是记在代币合约的账本上的）
        //代币（ERC20）永远不会离开它自己的合约代码。所谓的“转账”，本质上只是记账权的变更。
        return _asset.balanceOf(address(this));
    }

    //如果你往金库里存入 assets 这么多钱，根据现在的行情，应该给你发多少张‘股票’（Shares）
     function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();//供应量
        // 如果 supply 为 0，那么 1:1 铸造金库份额
        // 如果 supply 不为0，那么按比例铸造
        //你得到的份额 = 你存入的资产 * 总份额\总资产
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

        //兑换
     function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // 如果 supply 为 0，那么 1:1 赎回基础资产
        // 如果 supply 不为0，那么按比例赎回
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    //======
    //我想存 100块钱，能给我多少股票？
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    //“我想买 100股，需要付多少钱？
    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    //“我想取 100块钱，需要销毁多少股票？”
    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    //“我手里有 100股，能赎回多少钱？
    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    //=======


    /*//////////////////////////////////////////////////////////////
                     存款/提款限额逻辑
    //////////////////////////////////////////////////////////////*/

    //如果用户想存 100 万，但金库上限只有 50 万，前端应该先调用 maxDeposit，发现超额了，直接禁用“存款”按钮，而不是让用户发送交易然后报错浪费 Gas
    //现状：返回 type(uint256).max（即 $2^{256}-1$）。含义：“敞开门做生意，存多少都行，没有上限。”
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    
    //出门组：有多少取多少
    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        //调用了 convertToAssets。意思是：你手里的股份，按现在的汇率，最多能换成多少钱。
        return convertToAssets(balanceOf(owner));
    }
    
    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        //直接返回 balanceOf(owner)。意思是：你手里有多少股份，就能赎回多少股份，不能透支。  
        return balanceOf(owner);
    }






 }