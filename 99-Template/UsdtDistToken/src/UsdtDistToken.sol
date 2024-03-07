// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "forge-std/console.sol";

/**
@author zebin@binschool.app wx:bkra50

买卖10%滑点，3%销毁，3%回流筑池（1.5%币、1.5%U），3%LP分红 （U到账），1%基金会（U到账）

1. 黑名单
功能：禁止交易、禁止转账

2. 白名单
功能：转账无阻，并且不收税

3. 启动交易
功能：交易未开启，只允许白名单加池子，加池子后开放交易

4. 杀机器人
功能：前3区块，非白名单的买入者进入黑名单

5. 买卖10%滑点
功能：交易税，其中3%销毁，7%进入留存在合约内

6. 代币兑换U进行分配
将合约内代币兑换成U，再进行分配。
其中：3%回流底池（1.5%币、1.5%U），3%LP分红，1%基金会。
*/

// IERC20 代币协议
interface IERC20 {
    //精度，表明代币的精度是多少，即小数位有多少位
    function decimals() external view returns (uint8);
    //代币符号，一般看到的就是代币符号
    function symbol() external view returns (string memory);
    //代币名称，一般是具体的有意义的英文名称
    function name() external view returns (string memory);
    //代币发行的总量，现在很多代币发行后总量不会改变，有些挖矿的币，总量会随着挖矿产出增多，有些代币的模式可能会通缩，即总量会变少
    function totalSupply() external view returns (uint256);
    //某个账户地址的代币余额，即某地址拥有该代币资产的数量
    function balanceOf(address account) external view returns (uint256);
    //转账，可以将代币转给别人，这种情况是资产拥有的地址主动把代币转给别人
    function transfer(address recipient, uint256 amount) external returns (bool);
    //授权额度，某个账户地址授权给使用者使用自己代币的额度，一般是授权给智能合约，让智能合约划转自己的资产
    function allowance(address owner, address spender) external view returns (uint256);
    //授权，将自己的代币资产授权给其他人使用，一般是授权给智能合约，请尽量不要授权给不明来源的智能合约，有可能会转走你的资产，
    function approve(address spender, uint256 amount) external returns (bool);
    //将指定账号地址的资产转给指定的接收地址，一般是智能合约调用，需要搭配上面的授权方法使用，授权了才能划转别人的代币资产
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //转账事件，一般区块浏览器是根据该事件来做代币转账记录，事件会存在公链节点的日志系统里
    event Transfer(address indexed from, address indexed to, uint256 value);
    //授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Dex Swap 路由接口，用于交易、添加流动性、获取工厂
interface ISwapRouter {
    //路由的工厂方法，用于创建代币交易对
    function factory() external pure returns (address);
    //将指定数量的代币path[0]兑换为另外一种代币path[path.length-1]，支持手续费滑点
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    //添加代币 tokenA、tokenB 交易对流动性
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

// Dex Swap 工厂接口，用于创建交易对
interface ISwapFactory {
    //创建代币 tokenA、tokenB 的交易对，也就是常说的 LP，LP 交易对本身也是一种代币
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// 权限管理
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        //合约创建者拥有权限，也可以填写具体的地址
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    //查看权限在哪个地址上
    function owner() public view returns (address) {
        return _owner;
    }

    //拥有权限才能调用
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //放弃权限
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    //转移权限
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 用户暂存代币兑换的 USDT
contract TokenDistributor {
    // 参数为 USDT 合约地址
    constructor (address token) {
        // 合约的 USDT 授权给创建者
        // 创建者是代币合约，授权数量为最大整数
        IERC20(token).approve(msg.sender, ~uint256(0));
    }
}

// 买卖10%滑点：3%销毁，3%回流筑池（1.5%币、1.5%U），3%LP分红，1%基金会（U到账）
abstract contract CommonToken is IERC20, Ownable {
    // 用于存储每个地址的余额数量
    mapping(address => uint256) private _balances;
    // 存储授权数量，资产拥有者 owner => 授权调用方 spender => 授权数量
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress; // 营销钱包地址：存放U，代币和lp
    address public dividendAddress; // 分红钱包地址：存放U

    string private _name; // 代币名称
    string private _symbol; // 代币符号
    uint8 private _decimals; // 代币精度

    uint256 public fundFee = 100; // 1%基金会（U到账）
    uint256 public dividendFee = 300; // LP分红税
    uint256 public burnFee = 300; // 销毁税
    uint256 public lpFee = 300; // 回流税

    address public mainPair; // 主交易对地址

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal; // 代币总量

    ISwapRouter public _swapRouter; // dex swap 路由地址
    bool private inSwap; // 是否正在交易，用于合约出售代币时加锁
    uint256 public numTokensSellToFund; // 合约出售代币的门槛，即达到这个数量时出售代币

    TokenDistributor _tokenDistributor; // USDT 暂存合约，因为 swap 不允许将代币返回给代币合约地址
    address private usdt; // 保存代币 usdt 地址

    uint256 private startTradeBlock; // 开放交易的区块，用于杀机器人
    
    mapping(address => bool) private _feeWhiteList; // 交易税白名单
    mapping(address => bool) private _blackList; // 黑名单

    address DEAD = 0x000000000000000000000000000000000000dEaD; // 黑洞地址

    // 交易锁，防止重入攻击
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // 构造函数
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_, address fundAddress_, address dividendAddress_){
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        // BSC PancakeSwap 路由地址
        _swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // BSC USDT 合约地址
        usdt = address(0x55d398326f99059fF775485246999027B3197955);

        //创建交易对
        mainPair = ISwapFactory(_swapRouter.factory()).createPair(address(this), usdt);
        //将合约的资产授权给路由地址
        _allowances[address(this)][address(_swapRouter)] = MAX;
        IERC20(usdt).approve(address(_swapRouter), MAX);

        // 总量
        _tTotal = supply_ * 10 ** _decimals;
        
        // 初始代币转给营销钱包
        _balances[fundAddress_] = _tTotal;
        emit Transfer(address(0), fundAddress_, _tTotal);

        fundAddress = fundAddress_; // 营销钱包
        dividendAddress = dividendAddress_; // 分红钱包

        //营销地址为手续费白名单
        _feeWhiteList[fundAddress_] = true;
        _feeWhiteList[dividendAddress_] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;//wzb?

        // 营销钱包卖出条件：总量的万分之一
        numTokensSellToFund = _tTotal / 10000;

        _tokenDistributor = new TokenDistributor(usdt);
    }

    // 转账处理函数
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
      console.log("****");
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount <= balanceOf(from), "Transfer amount is greater than the balance");

        // 黑名单不允许转出
        require(!_blackList[from], "Transfer from the blackList address");

        bool takeFee = false;

        // 交易扣税，from == mainPair 表示买入，to == mainPair 表示卖出
        if (from == mainPair || to == mainPair) {
            // 交易未开启，只允许手续费白名单加池子，加池子即开放交易
            if (0 == startTradeBlock) {
                require(_feeWhiteList[from] || _feeWhiteList[to], "Trade not start");
                startTradeBlock = block.number;
            }

            // 不在手续费白名单，需要扣交易税
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;

                // 杀 0、1、2 区块的交易机器人
                if (block.number <= startTradeBlock + 2) {
                    // 将买入者加入黑名单
                    if (to != mainPair) {
                        _blackList[to] = true;
                    }
                }

                // 兑换资产到营销钱包
                uint256 contractTokenBalance = balanceOf(address(this));
                if (
                    contractTokenBalance >= numTokensSellToFund &&
                    !inSwap &&
                    from != mainPair // 有人卖出时触发检测
                ) {
                    swapTokenForFund(numTokensSellToFund);
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    // 扣交易税处理
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        // 转出者减少余额
        _balances[sender] = _balances[sender] - tAmount;

        uint256 feeAmount;
        if (takeFee) {
            feeAmount = tAmount * (lpFee + fundFee + dividendFee) / 10000;
            // 除销毁的代币，其它交易税放在合约内，用于兑换U
            _addReceiverBalance(sender, address(this), feeAmount);
            // 销毁代币
            uint256 burnAmount = tAmount * (burnFee) / 10000;
            _addReceiverBalance(sender, DEAD, burnAmount);
            // 总手续费
            feeAmount = feeAmount + burnAmount;
        }

        // 接收者增加余额
        tAmount = tAmount - feeAmount;
        _addReceiverBalance(sender, recipient, tAmount);
    }

    // 给接收者增加余额
    function _addReceiverBalance(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        // 预留加LP池子部分的代币
        uint256 lpAmount = tokenAmount * lpFee / (lpFee + dividendFee + fundFee) / 2;

        IERC20 USDT = IERC20(usdt);
        uint256 initialBalance = USDT.balanceOf(address(_tokenDistributor));

        // 将代币兑换为USDT
        swapTokensForUsdt(tokenAmount - lpAmount);

        uint256 newBalance = USDT.balanceOf(address(_tokenDistributor)) - initialBalance;
        uint256 totalUsdtFee = lpFee / 2 + dividendFee + fundFee;
        
        // 基金会 1%，放到营销钱包
        USDT.transferFrom(address(_tokenDistributor), fundAddress, newBalance * fundFee / totalUsdtFee);

        // LP分红税 3%，放到分红地址
        USDT.transferFrom(address(_tokenDistributor), dividendAddress, newBalance * dividendFee / totalUsdtFee);

        // 添加底池的U
        uint256 lpUsdt = newBalance * lpFee / 2 / totalUsdtFee;
        USDT.transferFrom(address(_tokenDistributor), address(this), lpUsdt);
        
        // 添加流动性
        addLiquidityUsdt(lpAmount, lpUsdt);
    }

    // 添加USDT交易对
    function addLiquidityUsdt(uint256 tokenAmount, uint256 usdtAmount) private {
        _swapRouter.addLiquidity(
            address(this),
            usdt,
            tokenAmount,
            usdtAmount,
            0,
            0,
            fundAddress,
            block.timestamp
        );
    }

    // 将合约内的代币兑换为USDT
    function swapTokensForUsdt(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount, // 兑换数量
            0, // accept any amount of ETH
            path, // 兑换路径
            address(_tokenDistributor), // 接收地址
            block.timestamp // 截止时间
        );
    }
    
    //设置交易手续费白名单
    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    // 查看是否手续费白名单
    function isFeeWhiteList(address addr) external view returns (bool){
        return _feeWhiteList[addr];
    }

    // 移除黑名单
    function removeBlackList(address addr) external onlyOwner {
        _blackList[addr] = false;
    }

    // 查看是否黑名单
    function isBlackList(address addr) external view returns (bool){
        return _blackList[addr];
    }

    // 提取合约内的代币
    function claimToken(address token, uint256 amount) public {
        IERC20(token).transfer(fundAddress, amount);
    }
    
    // 以下为ERC20标准函数
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract UsdtDistToken is CommonToken {
    constructor() CommonToken(
    // 名称
        "UsdtDistToken",
    // 符号
        "UDT",
    // 精度
        18,
    // 总量 10000
        10000,
    // 营销地址
        address(0x5A198036702A6354315B584Fe602Cfbc90D5183A),
    // 分红地址,
        address(0x3086389895D9Dc240993F60F1633fb1Cf0ADec9A)
    ){

    }
}