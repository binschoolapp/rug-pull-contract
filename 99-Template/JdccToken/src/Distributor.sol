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

contract TokenReservoir is Ownable {
  constructor() Ownable(msg.sender){
  }

  function permit(address jdcc) external onlyOwner {
    IERC20(jdcc).approve(owner(), type(uint256).max);
  }
}

contract Distributor is Ownable {
  // for miner reward
  uint256 public lastMinerTime;
  uint256 private _lastMinerBalance;
  uint256 private _lastMinerCount;
  uint256 private _minerIndex;

  // for lp reward
  uint256 public lastLPTime;
  uint256 private _lastLPBalance;
  uint256 private _lastLPCount;
  uint256 private _LPIndex;

  TokenReservoir private _lpReservoir;
  address public reservoir; 

  // for safety
  bool private locked; 
  modifier nonReentrant() {
    locked = true;
    _;
    locked = false;
  }

  constructor() Ownable(msg.sender) {
    uint256 currentTime = block.timestamp;
    lastMinerTime = currentTime;
    lastLPTime = currentTime;
    
    _lpReservoir = new TokenReservoir();
    reservoir = address(_lpReservoir);
  }

  uint256 public minAmountDist = 10 ether;
  function setMinAmountDist(uint256 _minAmountDist) external onlyOwner{
    minAmountDist = _minAmountDist;
  }

  uint256 public minCountPerRound = 30;
  function setMinCountPerRound(uint256 _minCountPerRound) external onlyOwner{
    minCountPerRound = _minCountPerRound;
  }

  event DistMinerToMembers(uint256 memberCount, uint256 amount);
  event DistMinerToMembersRound(uint256 currentIndex);
  function distributeMiner() external nonReentrant returns(bool) {
    if(jdcc == address(0) || _msgSender() != jdcc) {
      return false;
    }

    uint256 currentTime = block.timestamp;
    if (currentTime - lastMinerTime < 1 days) {
      return false;
    }

    uint256 currentMemberCount = globalDividendList.length;
    if (_minerIndex == 0) {
      uint256 totalBalance = IERC20(jdcc).balanceOf(address(this));
      if (totalBalance < minAmountDist){
        return false;
      }
      _lastMinerBalance = totalBalance;
      _lastMinerCount = currentMemberCount;
      emit DistMinerToMembers(currentMemberCount, totalBalance);
    }

    uint256 lastTotalBalance = _lastMinerBalance;
    uint256 totalCount = _lastMinerCount < currentMemberCount?_lastMinerCount:currentMemberCount;

    uint256 count = 0;
    for (uint256 i=_minerIndex; i<totalCount;) {
      address account = globalDividendList[i];
      uint256 radio = _getDividendRadio(account);
      uint256 amount = lastTotalBalance * radio / 1_000_000;
      if (amount > 0) {
        uint bal = IERC20(jdcc).balanceOf(address(this));
        if(bal < amount) {
          _minerIndex = 0;
          lastMinerTime = currentTime;
          return true;
        }
        IERC20(jdcc).transfer(account, amount);
      }
      i++;
      _minerIndex = i;
      count++;
      if (count >= minCountPerRound) {
        break;
      }
    }
    emit DistMinerToMembersRound(_minerIndex);
    if(_minerIndex < totalCount) {
      return true;
    }
    _minerIndex = 0;
    lastMinerTime = currentTime;
    return true;
  }

  event DistLPToMembers(uint256 memberCount, uint256 amount);
  event DistLPToMembersRound(uint256 currentIndex);
  function distributeLP() external nonReentrant returns(bool) {
    if(jdcc == address(0) || _msgSender() != jdcc) {
      return false;
    }

    uint256 currentTime = block.timestamp;
    if (currentTime - lastLPTime < 1 days) {
      return false;
    }

    uint256 currentMemberCount = globalDividendList.length;
    if (_LPIndex == 0) {
      uint256 totalBalance = IERC20(jdcc).balanceOf(reservoir);
      if (totalBalance < minAmountDist){
        return false;
      }
      _lastLPBalance = totalBalance;
      _lastLPCount = currentMemberCount;
      emit DistLPToMembers(currentMemberCount, totalBalance);
    }

    uint256 lastTotalBalance = _lastLPBalance;
    uint256 totalCount = _lastLPCount < currentMemberCount?_lastLPCount:currentMemberCount;

    uint256 count = 0;
    for (uint256 i=_LPIndex; i<totalCount;) {
      address account = globalDividendList[i];
      uint256 radio = _getFundRadio(account);
      uint256 amount = lastTotalBalance * radio / 1_000_000;
 
      if (amount > 0) {
        uint bal = IERC20(jdcc).balanceOf(reservoir);
        if(bal < amount) {
          _LPIndex = 0;
          lastLPTime = currentTime;
          return true;
        }
        IERC20(jdcc).transferFrom(reservoir,account, amount);
      }
      i++;
      _LPIndex = i;
      count++;
      if (count >= minCountPerRound) {
        break;
      }
    }
    emit DistLPToMembersRound(_LPIndex);
    if(_LPIndex < totalCount) {
      return true;
    }
    _LPIndex = 0;
    lastLPTime = currentTime;
    return true;
  }

  function withdrawToken(address account) external onlyOwner {
    require(jdcc != address(0), "uninitialized jdcc address");
    IERC20(jdcc).transfer(account, IERC20(jdcc).balanceOf(address(this)));
  }

  function withdraw(address payable account) external onlyOwner {
    account.transfer(address(this).balance);
  }

  receive() external payable {}

  address public jdcc;
  function setJDCC(address _jdcc) external onlyOwner {
    jdcc = _jdcc;
    _lpReservoir.permit(jdcc);
  }

  function addGlobalDividendList(address account) private {
    globalDividendList.push(account);
  }

  function removeGlobalDividendList(address account) private {
    uint256 len = globalDividendList.length;
    for (uint i = 0; i <len - 1; i++) {
      if (globalDividendList[i] == account) {
        globalDividendList[i] = globalDividendList[len - 1];
        globalDividendList.pop();
        break;
      }
    }
  }

  address[] public lchList;
  mapping(address => bool) private _lchSet;
  function lchCount() public view returns (uint256) {
    return lchList.length;
  }

  function setLch(address[] memory accounts) external onlyOwner {
    uint256 len = accounts.length;
    for (uint256 i=0; i < len; i++) {
      address account = accounts[i];
      if (_lchSet[account])
        continue;
      _lchSet[account] = true;
      lchList.push(account);
      addGlobalDividendList(account);
    }
  }

  function removeLx(address account) external onlyOwner {
    if (!_lchSet[account]){
      return;
    }
    uint256 len = lchList.length;
    for (uint i = 0; i <len; i++) {
      if (lchList[i] == account) {
        lchList[i] = lchList[len - 1];
        lchList.pop();
        _lchSet[account] = false;
        removeGlobalDividendList(account);
        break;
      }
    }
  }

  address[] public sxyList;
  mapping(address => bool) private _sxySet;
  function sxyCount() public view returns (uint256) {
    return sxyList.length;
  }

  function setSxy(address[] memory accounts) external onlyOwner {
    uint256 len = accounts.length;
    for (uint256 i=0; i < len; i++) {
      address account = accounts[i];
      if (_sxySet[account])
        continue;
      _sxySet[account] = true;
      sxyList.push(account);
      addGlobalDividendList(account);
    }
  }

  function removeSxy(address account) external onlyOwner {
    if (!_sxySet[account]){
      return;
    }
    uint256 len = sxyList.length;
    for (uint i = 0; i <len; i++) {
      if (sxyList[i] == account) {
        sxyList[i] = sxyList[len - 1];
        sxyList.pop();
        _sxySet[account] = false;
        removeGlobalDividendList(account);
        break;
      }
    }
  }
 
  address[] public opList;
  mapping(address => bool) private _opSet;
  function opCount() public view returns (uint256) {
    return opList.length;
  }

  function setOp(address[] memory accounts) external onlyOwner {
    uint256 len = accounts.length;
    for (uint256 i=0; i < len; i++) {
      address account = accounts[i];
      if (_opSet[account])
        continue;
      _opSet[account] = true;
      opList.push(account);
      addGlobalDividendList(account);
    }
  }

  function removeOp(address account) external onlyOwner {
    if (!_opSet[account]){
      return;
    }
    uint256 len = opList.length;
    for (uint i = 0; i <len; i++) {
      if (opList[i] == account) {
        opList[i] = opList[len - 1];
        opList.pop();
        _opSet[account] = false;
        removeGlobalDividendList(account);
        break;
      }
    }
  }

  struct DividendInfo {
    address account;
    uint256 ratio;
  }

  address[] public daoList;
  mapping(address => DividendInfo) private _daoSet;
  function daoCount() public view returns (uint256) {
    return daoList.length;
  }

  function setDao(address account, uint256 ratio) external onlyOwner {
    DividendInfo storage dividendInfo = _daoSet[account];
    if (dividendInfo.account != address(0)) return;
    _daoSet[account] = DividendInfo({
      account: account,
      ratio: ratio
    });
    daoList.push(account);
    addGlobalDividendList(account);
  }

  function removeDao(address account) external onlyOwner {
    DividendInfo storage dividendInfo = _daoSet[account];
    if (dividendInfo.account == address(0)) return;
  
    uint256 len = daoList.length;
    for (uint i = 0; i <len; i++) {
      if (daoList[i] == account) {
        daoList[i] = daoList[len - 1];
        daoList.pop();
        delete _daoSet[account];
        removeGlobalDividendList(account);
        break;
      }
    }
  }

  address[] private globalDividendList;
  function GlobalCount() public view returns (uint256) {
    return globalDividendList.length;
  }

  function _getDividendRadio(address account) private view returns (uint256) {
    if( _lchSet[account] ) {
      return 140_000 / lchCount();
    } 
    if( _sxySet[account] ) {
      return 24_000 / sxyCount();
    }
    if( _opSet[account] ) {
      return 7_200 / opCount();
    }
    DividendInfo memory dividendInfo = _daoSet[account];
    if (dividendInfo.account != address(0)) {
      return 36_000 * dividendInfo.ratio / 100;
    }
  
    return 0;
  }

  function _getFundRadio(address account) private view returns (uint256) {
    if( _lchSet[account] ) {
      return 300_000 / lchCount();
    } 
    if( _sxySet[account] ) {
      return 200_000 / sxyCount();
    }
    if( _opSet[account] ) {
      return 200_000 / opCount();
    }
    DividendInfo memory dividendInfo = _daoSet[account];
    if (dividendInfo.account != address(0)) {
      return 300_000 * dividendInfo.ratio /100;
    }
  
    return 0;
  }
}