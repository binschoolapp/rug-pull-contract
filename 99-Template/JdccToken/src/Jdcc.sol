// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IERC20Errors {
  error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
  error ERC20InvalidSender(address sender);
  error ERC20InvalidReceiver(address receiver);
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
  error ERC20InvalidApprover(address approver);
  error ERC20InvalidSpender(address spender);
}

library Math {
  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

interface ISwapRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);

}

interface ISwapPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function sync() external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function kLast() external view returns (uint256);
}

interface IWBNB {
    function deposit() external payable;
}

interface IDistributor {
  function distributeMiner() external returns(bool);
  function distributeLP() external returns(bool);
}

contract TokenReservoir {
}

contract JDCC is Context, IERC20, IERC20Errors, Ownable {
  // mint supply
  uint256 private constant TOTAL_SUPPLY = 310_000 ether; 
  uint256 private constant MAX_BUY_LIMIT = 300 ether;

  // trade tax
  uint256 private _burnFee = 150; 
  uint256 private _lpRewardFee = 50; 
  uint256 private _poolFee = 50; 
  uint256 private _fundFee = 100;
  uint256 private _insureFee = 50;
  uint256 private _fundFeeExtra = 2600;

  // swap
  ISwapRouter private immutable swapRouter; 
  address public immutable mainPair;
  
  address public immutable swapRouterAddress;
  address public immutable wbnbAddress;
  
  // reward 
  address public immutable poolReservoir; // for pool
  address public immutable lpDistributor; // for lp

  // erc20
  mapping(address account => uint256) private _balances;
  mapping(address account => mapping(address spender => uint256)) private _allowances;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _totalSupply;

  uint256 private _startTime; 
  uint256 private _totalSupplyLP;
    
  // start switch
  bool public start;
  function startRun() external onlyOwner(){
    uint256 currentTime = block.timestamp;
    _startTime = currentTime;
    _lastDeflationTime = currentTime;
    _lastMinerTime = currentTime;
    _lastLpTime = currentTime;
    _lastLPSwapTime = currentTime;
    _lastIndependentTime = currentTime; 
    start = true;   
  }
  
  function stopRun() external onlyOwner(){
    start = false;   
  }

  // safety lock
  bool private locked; 
  modifier nonReentrant() {
    locked = true;
    _;
    locked = false;
  }

   constructor() Ownable(msg.sender) payable {
      // erc20
      _name = "JDCC";
      _symbol = "JDCC";
      _decimals = 18;

      // task timer
      uint256 currentTime = block.timestamp;
      _startTime = currentTime;
      _lastDeflationTime = currentTime;
      _lastMinerTime = currentTime;
      _lastLpTime = currentTime;
      _lastLPSwapTime = currentTime;
      _lastIndependentTime = currentTime; 

      // mint token
      address sender = _msgSender();
      _mint(sender, TOTAL_SUPPLY - MINING_P1_AMOUNT);
      _mint(address(this), MINING_P1_AMOUNT); 

      // create swap pair
      // chainid 56 for mainnet, 97 for testnet
      swapRouterAddress = block.chainid == 56? 
          0x10ED43C718714eb63d5aA57B78B54704E256024E : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; 
      swapRouter = ISwapRouter(swapRouterAddress);
      wbnbAddress = swapRouter.WETH();
      mainPair = ISwapFactory(swapRouter.factory()).createPair(address(this), wbnbAddress);

      // approve all the token contract allowances to swap router
      _allowances[address(this)][address(swapRouter)] = type(uint256).max;

      // create pool contract to save tax of the trade
      poolReservoir = address(new TokenReservoir());
      _allowances[poolReservoir][address(this)] = type(uint256).max;

      // create distributor contract to reward lp
      lpDistributor = address(new TokenReservoir());
      _allowances[lpDistributor][address(this)] = type(uint256).max;

      // whitelist for free trade
      whitelist[sender] = true;
      whitelist[address(this)] = true;
      whitelist[poolReservoir] = true;
      whitelist[lpDistributor] = true;
    }

    event DistMinerToOrg(bool);
    event DistMinerToLP(bool);

    event AddLPLog(bool, address, address);
    event RemoveLPLog(bool, address, address, address, uint256);
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

      if (from == fundAddress || from == fundReservoirAddress) {
        _update(from, to, amount);
        return;
      }

      address sender = _msgSender();
      if (to == mainPair && sender == swapRouterAddress) {
        if (blacklist[from]) {
          revert("in the blacklist");
        }

        (bool added, ) = _addLiquidity(amount);
        if(added) {
          if(lpSet[from].account == address(0)) {
            User memory userNew = User(from, false);
            lpList.push(from);
            lpSet[from] = userNew;
          }
        }
        emit AddLPLog(added,from,sender);
      } else if (from == mainPair && sender == mainPair) {
        (bool removed,) = _removeLiquidity(amount);
        uint256 lpBalance = IERC20(mainPair).balanceOf(to);
        emit RemoveLPLog(removed, from, sender, to, lpBalance);
        if (removed) {
          if (isInitLp(to) || lpSet[to].account == address(0)) {
            _burn(from, amount);
            return;
          }
        }
      }

      uint256 currentTime = block.timestamp;
      bool executed;
      if (start) {
        if (from != mainPair) {
          executed = _deflate(currentTime);
        } 

        if (!executed && from != mainPair) {
          executed = _swapLPTokensForWBNB(currentTime);
        }
  
        if (!executed && from != mainPair) {
          executed = _processMinerDividend(currentTime);
        }
      
        if (!executed && from != mainPair) {
          executed = _processLpDividend(currentTime);
        }

        if (!executed && from != mainPair) {
          if (fundAddress != address(0) && currentTime - _lastIndependentTime > INDEPENDENT_DIVIDEND_FREQ) {
              executed = IDistributor(fundAddress).distributeMiner();
              emit DistMinerToOrg(executed);
            if (!executed) {
              executed = IDistributor(fundAddress).distributeLP();
              emit DistMinerToLP(executed);
            }
          }
        }
      }

      // calculate transaction tax calculations, and add or remove liquidity
      uint256 feeAmount;
      if (from == mainPair || to == mainPair) {
        require(start, "not start");

        uint256 passedTime = currentTime - _startTime;

        // // purchase limit within 2 hours after going online
        // if( !whitelist[from] && !whitelist[to] ) {
        //   if (passedTime < 2 hours && from == mainPair && amount > MAX_BUY_LIMIT ) {
        //     revert("exceeded maximum buy amount");
        //   }
        // }

        // prevent plummeting within 24 hours after going online
        if (passedTime < 24 hours && to == mainPair && enableSellLimit && amount > maxSellAmount ) {
          revert("exceeded maximum sell amount");
        }

        feeAmount = _calcFee(from, to, amount);
      }

      _update(from, to, amount - feeAmount);
    }

    function _calcFee(address from, address to, uint256 amount) private returns(uint256){
      if (whitelist[from] || whitelist[to]) {
        return 0;
      }

      uint256 burnAmount = amount * _burnFee / 10000;
      _burn(from, burnAmount);

      uint256 fundAmount = amount * _fundFee / 10000;
      _update(from, fundReservoirAddress, fundAmount);

      uint256 fundAmountExtra;
      if (block.timestamp - _startTime < 2 hours && to == mainPair) {
        fundAmountExtra = amount * _fundFeeExtra / 10000;
        _update(from, fundAddress, fundAmountExtra);
      }

      uint256 poolAmount = amount * _poolFee / 10000;
      _update(from, poolReservoir, poolAmount);

      uint256 lpRewardAmount = amount * _lpRewardFee / 10000;
      _update(from, lpDistributor, lpRewardAmount);

      uint256 insureAmount = amount * _insureFee / 10000;
      _update(from, insureAddress, insureAmount);
      
      return fundAmount + fundAmountExtra + poolAmount + lpRewardAmount + burnAmount + insureAmount;
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

    // liquidity event
    event AddLiquidity(uint256 amount);
    event RemoveLiquidity(uint256 amount);

    function _addLiquidity(uint256 amount) private returns (bool added, uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
            if(liquidity > 0) {
              added = true;
            }
            _totalSupplyLP += liquidity;
            emit AddLiquidity(_totalSupplyLP);
        }
    }

    function _removeLiquidity(uint256 amount) private returns (bool removed, uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        bool added;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            added = true;
        }

        ISwapPair swapPair = ISwapPair(mainPair);
        uint256 totalSupplyLP = swapPair.totalSupply();
        if(totalSupplyLP != _totalSupplyLP) {
          if(!added) removed = true;
          liquidity = totalSupplyLP;
          _totalSupplyLP = totalSupplyLP;
          emit RemoveLiquidity(totalSupplyLP);
        }
    }
    
    function calLiquidity(uint256 balanceA, uint256 amount, uint256 r0,uint256 r1) 
        private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(mainPair).totalSupply();
        address feeTo = ISwapFactory(swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator;
                    uint256 denominator;
                    if (swapRouterAddress == address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) {// BSC Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                        denominator = rootK * 17 + (rootKLast * 8);
                    } else if (swapRouterAddress == address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)) {//BSC testnet Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 3 + rootKLast;
                    } else if (swapRouterAddress == address(0xE9d6f80028671279a28790bb4007B10B0595Def1)) {//PG W3Swap
                        numerator = pairTotalSupply * (rootK - rootKLast) * 3;
                        denominator = rootK * 5 + rootKLast;
                    } else {//SushiSwap,UniSwap,OK Cherry Swap
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 5 + rootKLast;
                    }
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _getReserves() private view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(wbnbAddress).balanceOf(mainPair);
    }

    function __getReserves() private view returns (uint256 rOther, uint256 rThis){
        ISwapPair swapPair = ISwapPair(mainPair);
        (uint r0, uint256 r1,) = swapPair.getReserves();

        address tokenOther = wbnbAddress;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }

    address public fundAddress;
    function setFundAddess(address _fundAddress) external onlyOwner(){
      fundAddress = _fundAddress;   
    }
    
    address public fundReservoirAddress;
    function setFundReservoirAddress(address _fundReservoirAddress) external onlyOwner(){
      fundReservoirAddress = _fundReservoirAddress;   
    }

    address public insureAddress; 
    function setInsureAddress(address _insureAddress) external onlyOwner(){
       insureAddress = _insureAddress;   
    }

    // to set init lp
    function setInitLP(address[] memory accounts) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i=0; i<len; i++) {
            address account = accounts[i];
            User storage user = lpSet[account];
            if (user.account == address(0)) {
              User memory userNew = User(account,true);
              lpList.push(account);
              lpSet[account] = userNew;
            } else {
              if (!user.isInit) {
                user.isInit = true;
              }
            }
        }
    }

    mapping(address => bool) public blacklist;
    function setBlacklist(address account, bool enable) external onlyOwner {
        blacklist[account] = enable;
    }

    mapping(address => bool) public whitelist; 
    function setWhitelist(address account, bool enable) external onlyOwner {
        whitelist[account] = enable;
    }

    // prevent plummeting
    bool public enableSellLimit; 
    uint256 public maxSellAmount;
    function setEnableSellLimit(bool _enableSellLimit) external onlyOwner{
        enableSellLimit = _enableSellLimit;
    }
    function setMaxSellAmount(uint256 _maxSellAmount) external onlyOwner{
        maxSellAmount = _maxSellAmount;
    }

    // assigned to institution
    uint256 private constant INDEPENDENT_DIVIDEND_FREQ = 10 minutes;
    uint256 private _lastIndependentTime;

    // unilateral deflation
    uint256 private constant DEFLATION_MIN = 5513 ether;
    uint256 private constant DEFLATION_FREQ = 1 hours;
    uint256 private _lastDeflationTime; 
    event Deflation(uint256 amount);

    function _deflate(uint256 currentTime) private nonReentrant returns(bool) {
      if (currentTime - _lastDeflationTime < DEFLATION_FREQ) {
        return false;
      }
      uint256 poolReservoirBalance = balanceOf(poolReservoir);
      uint totalAmount = balanceOf(mainPair) + poolReservoirBalance;
      if(totalAmount <= DEFLATION_MIN) {
        _lastDeflationTime = currentTime;
        return false;
      }

      uint256 passedSeconds = currentTime - _lastDeflationTime;
      uint256 passedHours = passedSeconds / DEFLATION_FREQ;
      if(passedHours > 3) {
        passedHours = 3;
      }
      uint256 rate = _getDeflationRate(passedSeconds);
      if (rate == 0 ){
        _lastDeflationTime = currentTime;
        return false;
      }

      uint256 amountReserved = totalAmount;
      for (uint256 i=0; i<passedHours; i++) {
        amountReserved = amountReserved * (1_000_000 - rate) / 1_000_000;
        if (amountReserved < DEFLATION_MIN) {
          amountReserved = DEFLATION_MIN;
          break;
        }
      }
      
      uint256 amountToBurn = totalAmount - amountReserved;
      if (amountToBurn == 0) {
        _lastDeflationTime = currentTime;
        return false;
      }
      if (poolReservoirBalance > 0) {
        _update(poolReservoir, mainPair, poolReservoirBalance);
      }
      _burn(mainPair, amountToBurn);

      ISwapPair pair = ISwapPair(mainPair);
      pair.sync();
      
      _lastDeflationTime = currentTime;
      emit Deflation(amountToBurn);
      return true;
    }

    function _getDeflationRate(uint256 passedSeconds) private pure returns(uint256){
      if (passedSeconds < 60 days ){ // 0.75%
        return 7500;
      } 
      if (passedSeconds < 150 days){ // 0.375%
        return 3750;
      } 
      if (passedSeconds < 240 days ){ // 0.1875%
        return 1875;
      } 
      if (passedSeconds < 2200 days ){ // 0.0468%
        return 468;
      }
      return 0;
    }

    // miner reward
    struct User {
      address account;
      bool isInit; // is startup
    }

    uint256 private constant DIVIDEND_MINER_FREQ = 1 days;
    uint256 private constant DIVIDEND_MINER_PEROID = 1 days;
    
    address[] public lpList;
    mapping(address => User) public lpSet;

    uint256 private _lastMinerTime;
    uint256 private _lastMinerBalance;
    uint256 private _lastMinerCount;
    uint256 private _minerIndex;
    uint256 private _lastLPMinerTotal;
    event MinerDividend(uint256 lpCount, uint256 amount);
    event MinerDividendRound(uint256 currentIndex);
    
    // reward 1 period
    uint256 constant MINING_P1_AMOUNT = 12_000 ether; 
    uint256 constant MINING_P1_DAYS = 60; 
    uint256 constant MINING_P1_RPD = 200 ether;

    function lpCount() public view returns (uint256) {
      return lpList.length;
    }

    function isInitLp(address account) public view returns(bool){
      return lpSet[account].isInit;
    }

    uint256 public minMinerDividend = 100 ether;
    function setMinMinerDividend(uint256 _minMinerDividend) external onlyOwner{
      minMinerDividend = _minMinerDividend;
    }

    // number of acounts assigned in each round
    uint256 public allocCountPerRound = 30;
    function setAllocCountPerRound(uint256 _allocCountPerRound) external onlyOwner{
      allocCountPerRound = _allocCountPerRound;
    }
    
    function _calcMinerDividend() private view returns(uint256) {
        uint256 balance = balanceOf(address(this));
        if(balance < 1 ether) {
          return 0;
        } else if(balance < MINING_P1_RPD) {
          return balance;
        }
        return MINING_P1_RPD;
    }

    function _processMinerDividend(uint256 currentTime) private nonReentrant returns(bool) {
      if (currentTime - _lastMinerTime < DIVIDEND_MINER_FREQ) {
        return false;
      }

      uint256 passedDays = (currentTime - _startTime)/ DIVIDEND_MINER_PEROID;
      if(passedDays > MINING_P1_DAYS + 30) {
        return false;
      }

      uint256 currentLPCount = lpList.length;
      if (_minerIndex == 0) {
        uint256 totalBalance = _calcMinerDividend();
        if (totalBalance < minMinerDividend){
          return false;
        }
     
        uint totalBalanceLP = IERC20(mainPair).totalSupply();
        if (totalBalanceLP == 0 || currentLPCount == 0) {
          _update(address(this), fundAddress, totalBalance);
          emit MinerDividend(currentLPCount, totalBalance);
          return false;
        }
     
        uint256 fundAmount = totalBalance * 20 / 100;
        _lastMinerCount = currentLPCount;
        _lastMinerBalance = totalBalance - fundAmount;
        _lastLPMinerTotal = totalBalanceLP;

        emit MinerDividend(currentLPCount, totalBalance);
        _update(address(this), fundAddress, fundAmount);
      }

      uint256 lastTotalBalance = _lastMinerBalance;
      uint256 totalCount = _lastMinerCount < currentLPCount?_lastMinerCount:currentLPCount;

      uint256 count = 0;
      for (uint256 i=_minerIndex; i<totalCount;) {
        address account = lpList[i];
        uint256 lpBalance = IERC20(mainPair).balanceOf(account);
        uint amount = lastTotalBalance * (lpBalance * 1_000_000 / _lastLPMinerTotal) / 1_000_000;
        if (amount > 0) {
          uint bal = balanceOf(address(this));
          if(bal < amount) {
            _minerIndex = 0;
            _lastMinerTime = currentTime;
            return true;
          }
          _update(address(this), account, amount);
        }
        i++;
        _minerIndex = i;
        count++;
        if (count >= allocCountPerRound) {
          break;
        }
      }
      emit MinerDividendRound(_minerIndex);
      if(_minerIndex < totalCount) {
        return true;
      }
      _minerIndex = 0;
      _lastMinerTime = currentTime;
      return true;
    }

    // lp reward swap
    uint256 private constant DIVIDEND_SWAP_FREQ = 25 minutes;
    uint256 private _lastLPSwapTime; 
    event LpSwap(uint256 amount);

    function _swapLPTokensForWBNB(uint256 currentTime) private nonReentrant returns(bool) {
      if (currentTime - _lastLPSwapTime < DIVIDEND_SWAP_FREQ) {
        return false;
      }

      uint256 tokenAmount = balanceOf(lpDistributor);
      if (tokenAmount < 10 ether) {
        _lastLPSwapTime = currentTime;
        return false;
      }

      _update(lpDistributor, address(this), tokenAmount);
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = wbnbAddress;
      swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0,
          path,
          address(this),
          block.timestamp
      );
      _lastLPSwapTime = currentTime;
      emit LpSwap(tokenAmount);
      return true;
    }

    uint256 public minLpDividend = 4 ether;
    function setMinLpDividend(uint256 _minLpDividend) external onlyOwner{
      minLpDividend = _minLpDividend;
    }

    // lp reward distribution
    uint256 private constant DIVIDEND_LP_FREQ = 1 days;
    uint256 private _lastLpTime;
    uint256 private _lastLpBalance;
    uint256 private _lastLpCount;
    uint256 private _lpIndex;
    uint256 private _lastLPRewardTotal;
    event LpDividend(uint256 lpCount, uint256 amount);
    event LPDividendRound(uint256 currentIndex);

    function _processLpDividend(uint256 currentTime) private nonReentrant returns(bool) {
      if (currentTime - _lastLpTime < DIVIDEND_LP_FREQ) {
        return false;
      }
   
      uint256 currentLPCount = lpList.length;
      if (_lpIndex == 0) {
        uint256 totalBalance = IERC20(wbnbAddress).balanceOf(address(this));
        if (totalBalance < minLpDividend){
          return false;
        }

        _lastLpBalance = totalBalance;
        _lastLpCount = currentLPCount;
        if (_lastLpCount == 0) {
          return false;
        }

        _lastLPRewardTotal = IERC20(mainPair).totalSupply();
        if (_lastLPRewardTotal == 0) {
          return false;
        }
        emit LpDividend(currentLPCount, totalBalance);
      }

      uint256 lastTotalBalance = _lastLpBalance;
      uint256 totalCount = _lastLpCount < currentLPCount?_lastLpCount:currentLPCount;

      uint256 count = 0;
      for (uint256 i=_lpIndex; i<totalCount;) {
        address account = lpList[i];
        uint256 lpBalance = IERC20(mainPair).balanceOf(account);
        uint amount = lastTotalBalance * (lpBalance * 1_000_000 / _lastLPRewardTotal) / 1_000_000;
        if (amount > 0) {
          uint bal = IERC20(wbnbAddress).balanceOf(address(this));
          if(bal < amount) {
            _lpIndex = 0;
            _lastLpTime = currentTime;
            return true;
          }
          IERC20(wbnbAddress).transfer(account, amount);
        }
        i++;
        _lpIndex = i;
        count++;
        if (count >= allocCountPerRound) {
          break;
        }
      }
      emit LPDividendRound(_lpIndex);
      if(_lpIndex < totalCount) {
        return true;
      }
      _lpIndex = 0;
      _lastLpTime = currentTime;
      return true;
    }

    function withdrawToken(address to) external onlyOwner {
      uint256 amount = balanceOf(address(this));
      require(amount > 0, "No tokens to withdraw");
      _transfer(address(this), to, amount);
    }

    function withdrawWBNB(address to) external onlyOwner {
      IERC20(wbnbAddress).transfer(to,IERC20(wbnbAddress).balanceOf(address(this)));
    }

    receive() external payable {
      IWBNB(wbnbAddress).deposit{value: msg.value}();
    }
}