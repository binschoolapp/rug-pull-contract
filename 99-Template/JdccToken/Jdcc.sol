// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/console.sol";

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
     function WETH() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function sync() external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// 用户暂存回流底池的代币
contract PoolReservoir {
    constructor () {
        // 合约授权给创建者
        // 创建者是代币合约，授权数量为最大整数
        IERC20(msg.sender).approve(msg.sender, type(uint256).max);
    }
}

// 主合约
contract JDCC is Context, IERC20, IERC20Errors, Ownable {
    // 代币数量
    uint256 private constant TOTAL_SUPPLY = 310_000*10**18; // 发行总量
    uint256 private constant MAX_BUY_LIMIT = 50*10**18; // 上线24小时内，限制买入量

    // 交易费用
    uint256 private _burnFee = 150; // 交易销毁 1.5%
    uint256 private _lpRewardFee = 50; // lp分红 0.5%
    uint256 private _poolFee = 50; // 回流底池 0.5%
    uint256 private _fundFee = 150; // 营销钱包 1.5%

    // BSC地址 
    ISwapRouter public immutable swapRouter; // Pancake 路由器
    address public immutable mainPair; // 交易对地址
    // BSC PancakeSwap
    address public constant swapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // BSC USDT
    address public constant WBNBAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;//0x55d398326f99059fF775485246999027B3197955;

    // 运营地址
    address public immutable fundAddress = 0xCCC2d4D475276D0EF57E41bBC4BB6c6c39Ef91a0; // 营销钱包地址
    mapping(address => bool) private _feeWhiteList; // 交易税白名单
    address public immutable _poolReservoir; // 回流底池的暂存地址
    
    // ERC20 变量
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    uint256 private _startTime;  // 合约部署时间

    mapping(address => bool) public _swapRouters;

    // 防止重入攻击
    bool private locked; 
    modifier nonReentrant() {
        require(!locked, "Function locked");
        locked = true;
        _;
        locked = false;
    }

   constructor() Ownable(msg.sender) {
        uint256 currentTime = block.timestamp;
        _startTime = currentTime;
        _lastDeflationTime = currentTime;
        _lastDividendTime = currentTime;

        _name = "JDCC Coin";
        _symbol = "JDCC";
        _decimals = 18;

        // 铸造分配代币
        _mint(_msgSender(), TOTAL_SUPPLY - MINING_P1_AMOUNT);
        _mint(address(this), MINING_P1_AMOUNT); // 预留1期分配

        // 创建代币到USDT的交易对
        swapRouter = ISwapRouter(swapRouterAddress);
        mainPair = ISwapFactory(swapRouter.factory()).createPair(address(this), WBNBAddress);
        // 将合约内代币全部授权给Swap路由
        _allowances[address(this)][address(swapRouter)] = type(uint256).max;

        // 创建底池代币暂存合约，代币来自于交易税
        _poolReservoir = address(new PoolReservoir());
        _allowances[_poolReservoir][address(this)] = type(uint256).max;

        // 手续费白名单
        _feeWhiteList[_msgSender()] = true;
        _feeWhiteList[address(this)] = true;
        _swapRouters[swapRouterAddress] = true;
    }

    function _transfer(address from, address to, uint256 amount) private  {
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

        // 上线24小时内限购
        // from == mainPair 买入
        // if (currentTime - _startTime < 24 hours && from == mainPair && amount > MAX_BUY_LIMIT) {
        //     revert("exceeded maximum buy amount");
        // }

        // 防止暴跌
        // to == mainPair 卖出; owner() != address(0) 所有权丢入黑洞后，不再限制
        if (to == mainPair && owner() != address(0) && enableSellLimit &&  amount > maxSellAmount) {
            revert("exceeded maximum sell amount");
        }
        // 交易税处理
        uint256 feeAmount;
        // from == mainPair 买入; to == mainPair 卖出
        if ((from == mainPair || to == mainPair) && amount > 0) {
            address txOrigin = tx.origin;
            if (to == mainPair && _msgSender() == swapRouterAddress && txOrigin == from) {
              // 添加 lp
            } else if(from == mainPair) &&

            // 不在手续费白名单，需要扣交易税
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
              // 销毁
              uint256 burnAmount = amount * _burnFee / 10000;
              _update(from, address(0), burnAmount);

              // 营销钱包
              uint256 fundAmount = amount * _fundFee / 10000;
              _update(from, fundAddress, fundAmount);
              
              // 回流底池
              uint256 poolAmount = amount * _poolFee / 10000;
              _update(from, _poolReservoir, poolAmount);

              // lp分红
              uint256 lpRewardAmount = amount * _lpRewardFee / 10000;
              _update(from, address(this), lpRewardAmount);

              // 扣除交易费
              feeAmount = fundAmount + poolAmount + lpRewardAmount + burnAmount;
            }
        }

        // 转账交易
        _update(from, to, amount - feeAmount);

        // 底池自动通缩
        if (currentTime >= _lastDeflationTime + _deflationFrequency) {
            _autoDeflation(currentTime);
        }

     //uint256 addLPLiquidity;
        if (to == mainPair && _swapRouters[msg.sender] /*&& txOrigin == from*/) {
          console.log("33333333333:",_isAddLiquidity() );
            // addLPLiquidity = _isAddLiquidity(amount);
            // if (addLPLiquidity > 0) {
            //     takeFee = false;
            //     userInfo = _userInfo[txOrigin];
            //     userInfo.lpAmount += addLPLiquidity;
            //     if (!launch) {
            //         userInfo.preLPAmount += addLPLiquidity;
            //     }
            // }
        }

        // 维护lp名单
        _manageLpList(from, to);

        // lp分红
        if (currentTime >= _lastDividendTime + 24 hours) {
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

    // 判断是否添加lp
    function _isAddLiquidity() private view returns (bool isAdd){
        return _isLiquidityIncreased();
    }

    // 判断是否移除lp
    function _isRemoveLiquidity() private view returns (bool isRemove){
        return !_isLiquidityIncreased();
    }

    // 判断lp是否增加
    function _isLiquidityIncreased() private view returns (bool){
        ISwapPair swapPair = ISwapPair(mainPair);
        (uint r0,uint256 r1,) = swapPair.getReserves();

        aaddress tokenOther = WBNBAddress;
        uint256 reserved;
        if (tokenOther < address(this)) {
            reserved = r0;
        } else {
            reserved = r1;
        }
        uint current = IERC20(tokenOther).balanceOf(mainPair);
        return current > reserved?true:false;
    }


    // 手续费白名单
    // 设置交易手续费白名单
    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    // 查看是否手续费白名单
    function isFeeWhiteList(address addr) external view returns (bool){
        return _feeWhiteList[addr];
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
    uint256 private constant MIN_POOL_RESERVED = 5513*10**18; // 底池保留最小量
    uint256 private _deflationFrequency = 1 hours; // 收缩频率：每小时1次
    uint256 private _deflationPercent = 75; // 通缩率：0.75%
    uint256 private _lastDeflationTime; // 最新一次通缩时间

    event AutoDeflation();

    // 自动通缩
    function _autoDeflation(uint256 currentTime) private {
        uint256 poolReservoirBalance = balanceOf(_poolReservoir);
        uint totalAmount = balanceOf(mainPair) + poolReservoirBalance;
        if(totalAmount <= MIN_POOL_RESERVED) {
          return;
        }

        uint256 passedHours = (currentTime - _lastDeflationTime) / _deflationFrequency;
        if(passedHours > 10) {
          passedHours = 10;
        }

        uint256 amountToBurn = 0;
        for (uint256 i=0; i<passedHours; i++) {
          amountToBurn += totalAmount * _deflationPercent / 10000;
          if (totalAmount - amountToBurn < MIN_POOL_RESERVED) {
            amountToBurn = totalAmount - MIN_POOL_RESERVED;
            break;
          }
          console.log("***",amountToBurn/(10**18));
          totalAmount -= amountToBurn;
        }
        if (amountToBurn == 0) return;

        _lastDeflationTime = currentTime;

        _update(_poolReservoir, mainPair, poolReservoirBalance);
        _burn(mainPair, amountToBurn);

        ISwapPair pair = ISwapPair(mainPair);
        pair.sync();
        emit AutoDeflation();
    }

    // lp分红机制
    address[] public lpList; // lp名单
    mapping(address => bool) private _lpSet; // 用于判断是否lp
    address private _pendingLp; // 待确定lp
    uint256 private _lastDividendTime; // 最新一次分红时间
  
    // 挖矿分配
    uint256 constant MINING_P1_AMOUNT = 120_00*10**18; // 第1阶段时间    
    uint256 constant MINING_P1_DAYS = 60; // 第1阶段时间
    uint256 constant MINING_P1_RPD = 2_00*10**18; // 第1阶段每日分红

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
        uint256 balance = balanceOf(address(this));
        uint256 passedDays = (currentTime - _startTime)/86400;

        // 超过1期后，分配合约内全部余额，也就是交易税分成
        if(passedDays > MINING_P1_DAYS) {
          return balance;
        }

        // 没有超过1期后，按实际日期分配
        uint256 leftAmount = (MINING_P1_DAYS - passedDays) * MINING_P1_RPD;
        return balance < leftAmount? 0:balance - leftAmount;
    }

    // 执行lp挖矿分红
    function _execLpDividend(uint256 currentTime) private {
        uint256 dividendAmount = _calcDividend(currentTime);
        if (dividendAmount == 0) return;

        _lastDividendTime = currentTime;
        uint256 totalLPBalance = IERC20(mainPair).totalSupply();
        for (uint i = 0; i < lpList.length; i++) {
            address lp = lpList[i];
            uint currentLPBlance = IERC20(mainPair).balanceOf(lp);
            uint currentAmount = dividendAmount * (currentLPBlance * 10000 / totalLPBalance) / 10000;
            if(currentAmount > 0) _update(address(this), lp, currentAmount);
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

=======require=====
    《JDCC数字资产》
    总发行量：100万枚
    其中矿池（预留用于挖矿）：50万枚
    黑洞：25万枚
    初始池子：25万枚


    挖矿分四个周期（50万枚）：
    第一期：60天200枚/每天
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