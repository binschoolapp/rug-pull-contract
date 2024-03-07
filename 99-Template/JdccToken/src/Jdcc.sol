// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/console.sol";

/**
@author zebin@binschool.app wx:bkra50
*/

// 元交易处理
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// 合约所有权管理
abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ERC20接口标准
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ERC20错误定义标准
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

// PancakeSwap路由接口
interface ISwapRouter {
    function factory() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function sync() external;
}

// 主合约
contract JDCC is Context, IERC20, IERC20Errors, Ownable {
    // 代币数量
    uint256 private constant TOTAL_SUPPLY = 1_000_000*10**18; // 发行总量
    uint256 private constant MINING_POOL_SUPPLY = 500_000*10**18;  // 矿池预留量
    uint256 private constant INITIAL_POOL_SUPPLY = 250_000*10**18; // 初始底池量
    uint256 private constant BLACK_HOLE_SUPPLY = 250_000*10**18; // 销毁量
    uint256 private constant LP_PROMOTION_SUPPLY = 100_000*10**18;  // LP推广福利

    // 交易费用
    uint256 public fundFee = 100; // 营销钱包 1%
    uint256 public poolFee = 50; // 回流底池 0.5%
    uint256 public lpRewardFee = 50; // lp分红 0.5%
    uint256 public burnFee = 100; // 交易销毁 1%

    // BSC地址 
    ISwapRouter public immutable swapRouter;
    address public immutable swapToken;

    // BSC PancakeSwap 路由: 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // BSC USDT 地址: 0x55d398326f99059fF775485246999027B3197955;
    // BSC WBNB 地址: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // 运营地址
    address public immutable mainPair; // 交易对地址
    address public immutable promotionAddress; // LP推广福利地址
    address public immutable poolAddress; // 底池地址
    
    // ERC20 变量
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // 内部变量 
    uint256 private _startTime;    // 合约部署时间

    // 防止重入攻击
    bool private locked; 
    modifier nonReentrant() {
        require(!locked, "Function locked");
        locked = true;
        _;
        locked = false;
    }

   constructor(
    address _swapRouterAddress, // pancak路由
    address _swapToken, // 兑换代币
    address _poolAddress, // 底池预留
    address _promotionAddress // lp推广预留
    ) Ownable(msg.sender) {
        swapRouter = ISwapRouter(_swapRouterAddress);
        swapToken = _swapToken;
        poolAddress = _poolAddress;
        promotionAddress = _promotionAddress;

        uint256 currentTime = block.timestamp;
        _startTime = currentTime;
        lastDividendTime = currentTime;

        _name = "JDCC Coin";
        _symbol = "JDCC";
        _decimals = 18;

        // 铸造分配代币
        _mint(address(this), TOTAL_SUPPLY); 
        _update(address(this), poolAddress, INITIAL_POOL_SUPPLY); // 分配给初始池子
        _update(address(this), promotionAddress, LP_PROMOTION_SUPPLY); // 分配给LP推广福利
        _burn(address(this), BLACK_HOLE_SUPPLY); // 销毁

        // 创建交易对，并授权路由
        mainPair = ISwapFactory(swapRouter.factory()).createPair(address(this), swapToken);
        _allowances[address(this)][address(swapRouter)] = type(uint256).max; // 将合约内代币全部授权给Swap路由
    }

    function _transfer(address from, address to, uint256 amount) private nonReentrant {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
        }

        uint256 currentTime = block.timestamp;

        // 上线24小时内限购50枚
        // from == mainPair 买入
        if (currentTime - _startTime < 24 hours && from == mainPair && amount > 50*10**18) {
            revert("exceeded maximum buy amount");
        }

        // 防止暴跌
        // to == mainPair 卖出
        if (enableSellLimit && to == mainPair && amount > maxSellAmount) {
            revert("exceeded maximum sell amount");
        }

        // 交易税处理
        uint256 feeAmount;
        // from == mainPair 买入; to == mainPair 卖出
        if ((from == mainPair || to == mainPair) && amount > 0) {
            // 营销钱包
            uint256 fundAmount = amount * fundFee / 10000;
            _balances[promotionAddress] += fundAmount;
            // 回流底池
            uint256 poolAmount = amount * poolFee / 10000;
            _balances[poolAddress] += poolAmount;
            // lp分红
            uint256 lpRewardAmount = amount * lpRewardFee / 10000;
            _balances[address(this)] += lpRewardAmount; 
            // 销毁
            uint256 burnAmount = amount * burnFee / 10000;
            _balances[address(0)] += burnAmount;

            // 扣除交易费
            feeAmount = fundAmount + poolAmount + lpRewardAmount + burnAmount;
            _balances[from] -= feeAmount;
        }

        // 转账交易
        _update(from, to, amount - feeAmount);

        // 底池自动通缩
        if (enableAutoDeflation && currentTime >= lastDeflationTime + deflationFrequency) {
            _autoDeflation(currentTime);
        }

        // 维护lp名单
        _manageLpList(from, to);

        // lp挖矿奖励
        if (enableDividend && currentTime >= lastDividendTime + 24 hours) {
           _execLpDividend(currentTime);
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

   function transfer(address to, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _update(address from, address to, uint256 value) private {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    // 防暴跌机制
    bool public enableSellLimit; // 是否启动卖出限制
    uint256 public maxSellAmount; // 最大卖出数量

    // 启动或停止卖出限制
    function setEnableSellLimit(bool _enableSellLimit) external onlyOwner{
        enableSellLimit = _enableSellLimit;
    }
    // 设置最大卖出数量
    function setMaxSellAmount(uint256 _maxSellAmount) external onlyOwner{
        maxSellAmount = _maxSellAmount;
    }

    // 自动通缩机制
    bool public enableAutoDeflation = false; // 启动自动通缩
    uint256 private deflationFrequency = 1 hours; // 收缩频率：每小时1次
    uint256 private deflationPercent = 100; // 通缩率：1%
    uint256 public lastDeflationTime; // 最新一次通缩时间

    event AutoDeflation();

    function setEnableAutoDeflation(bool _enableAutoDeflation) external onlyOwner {
        enableAutoDeflation = _enableAutoDeflation;
        lastDeflationTime = block.timestamp;
    }

    // 自动通缩
    function _autoDeflation(uint256 currentTime) private {
        uint256 passedHours = (currentTime - lastDeflationTime) / deflationFrequency;
        if( passedHours > 10) {
          passedHours = 10;
        }
        lastDeflationTime = currentTime;

        uint256 poolBalance = balanceOf(mainPair);
        uint256 amountToBurn = 0;
        for (uint256 i=0; i<passedHours; i++) {
          amountToBurn += poolBalance * deflationPercent / 10000;
          poolBalance -= amountToBurn;
        }
        if (amountToBurn > 0) {
            _burn(mainPair, amountToBurn);
        }

        ISwapPair pair = ISwapPair(mainPair);
        pair.sync();
        emit AutoDeflation();
    }

    // lp分红机制
    mapping(address => bool) private _lpSet; // 用于判断是否lp
    address[] public lpList; // lp名单
    address private _pendingLp; // 待确定lp
    uint256 public lastDividendTime; // 最新一次分红时间
    bool public enableDividend; // 分红标志

    // 挖矿分配
    uint256 private constant MINING_TOTAL_AMOUNT = 400_000*10**18; // 挖矿奖励总量

    uint256 private constant MINING_P1_AMOUNT = 120_000*10**18; // 第1阶段时间    
    uint256 private constant MINING_P1_DAYS = 60; // 第1阶段时间
    uint256 private constant MINING_P1_RPD = 2_000*10**18; // 第1阶段每日分红

    uint256 private constant MINING_P2_AMOUNT = 90_000*10**18; // 第2阶段时间   
    uint256 private constant MINING_P2_DAYS = 90; // 第2阶段时间
    uint256 private constant MINING_P2_RPD = 1_000*10**18; // 第2阶段每日分红

    uint256 private constant MINING_P3_AMOUNT = 45_000*10**18; // 第2阶段时间  
    uint256 private constant MINING_P3_DAYS = 90; // 第3阶段时间
    uint256 private constant MINING_P3_RPD = 500*10**18; // 第3阶段每日分红

    uint256 private constant MINING_P4_DAYS = 1960; // 第4阶段时间
    uint256 private constant MINING_P4_RPD = 74*10**18; // 第4阶段每日分红

    function setEnableDividend(bool _enableDividend) external onlyOwner {
        if (_enableDividend) {
          lastDividendTime = block.timestamp;
        }
        enableDividend = _enableDividend;
    }

    function lpCount() external view returns (uint256) {
      return lpList.length;
    }

    // 维护lp名单
    function _manageLpList(address from,  address to) private {
      address account = _pendingLp;
      if (from == mainPair) {
        _pendingLp = to;
      } else if (to == mainPair) {
        _pendingLp = from;
      } else if (account != address(0)) {
        _pendingLp = address(0);
      }

      if (account == address(0) ) {
        return;
      }

      if (IERC20(mainPair).balanceOf(account) == 0) {
          if (_lpSet[account]) {
              _lpSet[account] = false;
              for (uint i = 0; i < lpList.length; i++) {
                  if (lpList[i] != account) {
                      continue;
                  }
                  lpList[i] = lpList[lpList.length - 1];
                  lpList.pop();
                  break; 
              }
          }
      } else {
        if (!_lpSet[account]) {
            _lpSet[account] = true;
            lpList.push(account);
        }
      }
    }

    // 计算当前分红量
    function _calcDividend(uint256 currentTime) private view returns(uint256) {
        if (currentTime <= lastDividendTime) {
          return 0;
        }

        uint256 passedDays = (currentTime - lastDividendTime)/86400;
        uint256 totalAmount = MINING_TOTAL_AMOUNT;
        if (passedDays <= MINING_P1_DAYS) {
            uint passedAmount = passedDays * MINING_P1_RPD;
            return balanceOf(address(this)) - (totalAmount - passedAmount);
        }
        totalAmount -= MINING_P1_AMOUNT;
        passedDays -= MINING_P1_DAYS;
        if (passedDays <= MINING_P2_DAYS) {
            uint256 passedAmount = passedDays * MINING_P2_RPD;
            return balanceOf(address(this)) - (totalAmount - passedAmount);
        }
        totalAmount -= MINING_P2_AMOUNT;
        passedDays -= MINING_P2_DAYS;

        if (passedDays <= MINING_P3_DAYS) {
            uint passedAmount = passedDays * MINING_P3_RPD;
            return balanceOf(address(this)) - (totalAmount - passedAmount);
        }
        totalAmount -= MINING_P3_AMOUNT;
        passedDays -= MINING_P3_DAYS;
      
        if (passedDays < MINING_P4_DAYS) {
            uint passedAmount = passedDays * MINING_P4_RPD;
            return balanceOf(address(this)) - (totalAmount - passedAmount);
        }
        return balanceOf(address(this));
    }

    // 执行lp挖矿分红
    function _execLpDividend(uint256 currentTime) private {
        uint256 totalAmount = _calcDividend(currentTime);
        if (totalAmount == 0) {
            return;
        }
        lastDividendTime = currentTime; 

        uint256 totalSupplyPair = IERC20(mainPair).totalSupply();
        for (uint i = 0; i < lpList.length; i++) {
            address lp = lpList[i];
            uint amountPair = IERC20(mainPair).balanceOf(lp);
            uint amount = totalAmount * (amountPair * 100 / totalSupplyPair) / 100;
            _update(address(this), lp, amount);
        }
    }
}

/*
=======usage=====
1. 部署提供4个地址：
   constructor(
    address _swapRouterAddress, // pancak路由
    address _swapToken, // 兑换代币
    address _poolAddress, // 底池预留
    address _promotionAddress // lp推广预留
    )
其中： 
_swapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E //pancak路由
_swapToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
_poolAddress // 底池预留,用于添加流动性，由项目方提供
_promotionAddress // lp推广预留，由项目方提供

2. 防止暴跌   
 // 是否启动卖出限制，管理员使用
  setEnableSellLimit(bool _enableSellLimit) external onlyOwner
  // 设置最大卖出数量，管理员使用
   setMaxSellAmount(uint256 _maxSellAmount) external onlyOwner
  两个函数配合使用。

3. 底池单边通缩
  // 是否启用单边通缩，管理员使用
  setEnableAutoDeflation(bool _enableAutoDeflation) external onlyOwner
  
4. 底池单边通缩
  // 是否启用分红机制，管理员使用
   setEnableDividend(bool _enableDividend) external onlyOwner
   

=======require=====
    《JDCC数字资产》
    总发行量：100万枚
    其中矿池（预留用于挖矿）：50万枚
    黑洞：25万枚
    初始池子：25万枚


    挖矿分四个周期（50万枚）：
    第一期：60天2000枚/每天
    第二期：90天 1000枚/每天
    第三期：90天   500枚/每天
    第四期：每天74枚1960天

    剩余10万 用于LP推广福利

    初始池子25万枚：由5000位有格局有共识基础的社区长联合坐庄而搭建的流动池，撤池币销毁，留下USDT！

    正常滑点
    买卖：交易税3% 
    其中1%销毁打入黑洞 
    0.5% LP分红
    0.5回流底池1%营销，

    底池每小时单边通缩1%进入黑洞。
    上线24小时限购每个帐户最多50枚！

    防爆跌机制！
    币价跌幅是多少滑点就是多少
*/