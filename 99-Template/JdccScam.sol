/**
* https://bscscan.com/token/0xcf192966b61456b38fd17c8b4ce07126cdb25312#code
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address _spender, uint _value) external;

    function transferFrom(address _from, address _to, uint _value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    address public _owner;
    constructor(address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner);
        IERC20(token).transfer(to, amount);
    }
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract AbsToken is IERC20, Ownable {
    string private _name = "JDCC";
    string private _symbol = "JDCC";
    uint256 private immutable _decimals = 18;
    uint256 public immutable kb = 60;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _rewardList;
    uint256 private immutable _tTotal;

    ISwapRouter public immutable _swapRouter;
    address public immutable currency;
    address public immutable _mainPair;
    mapping(address => bool) public _swapPairList;

    address public fundAddress;

    bool public antiSYNC = true;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    TokenDistributor public immutable _LPRewardDistributor;
    TokenDistributor public immutable _DAORewardDistributor;
    TokenDistributor public immutable _inviterRewardDistributor;

    uint256 public immutable _buyFundFee = 150;
    uint256 public immutable _buyLPFee = 50;
    uint256 public immutable _buyLPDividendFee = 100;
    uint256 public immutable buy_burnFee = 100;
    uint256 public immutable _sellFundFee = 150;
    uint256 public immutable _sellLPFee = 50;
    uint256 public immutable _sellLPDividendFee = 100;
    uint256 public immutable sell_burnFee = 100;

    uint256 public immutable fristRate = 15;

    uint256 public removeLiquidityFee = 100;

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;
    mapping(address => mapping(address => bool)) public _maybeInvitor;

    uint256 public startTradeBlock;

    mapping(address => uint256) public _userLPAmount;
    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    bool public immutable enableOffTrade = true;
    bool public immutable enableKillBlock = true;
    bool public immutable enableRewardList = true;

    uint256 public minLPHoldAmount;
    uint256 public  _mineStartTime;
    uint256 public immutable _mineRewardTimeDebt = 1 days;

    uint256 public _mineLPRewardDays;
    uint256 public _currentMineLPIndex;
    uint256 public _progressMineLPBlock;
    uint256 public immutable _progressMineLPBlockDebt = 1;
    // mapping(address => uint256) public _lastMineLPRewardTimes;
    mapping(uint256 => uint256) public _mineLPRewards;

    uint256 public _mineDAORewardDays;
    address[] public daoProviders;
    uint256 public _totalDAOWeight;
    mapping(address => uint256) public daoProviderIndex;
    mapping(address => uint256) public _userDAOAmount;
    mapping(uint256 => bool) public _mineDAORewardTimes;

    address[] public dividedProviders;
    uint256 public _totalDividendWeight;
    mapping(address => uint256) public dividedProviderIndex;
    mapping(address => uint256) public _userDividendAmount;
    uint256 public  dividendCondition = 1 ether;
    uint256 public _dividedAmount;

    uint256 public _currentDividendLPIndex;
    uint256 public _progressDividendLPBlock;
    uint256 public immutable _progressDividendLPBlockDebt = 100;
    uint256 public  LPDividendCondition = 1 ether;

    uint256 public _rewardGas = 500000;
    mapping(address => bool) public _swapContract;

    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_addLiquidityETH();

    constructor(
        address swapRouter_,
        address receiveAddress_,
        address fundAddress_
    ) {
        _tTotal = 310000 * 10 ** _decimals;

        fundAddress = fundAddress_;
        _swapRouter = ISwapRouter(swapRouter_);
        currency = _swapRouter.WETH();
        address ReceiveAddress = receiveAddress_;
        IERC20(currency).approve(address(_swapRouter), MAX);
        _allowances[address(this)][address(_swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        _mainPair = swapFactory.createPair(address(this), currency);

        _swapPairList[_mainPair] = true;

        minLPHoldAmount = 1 * 10 ** _decimals / 10000;

        _LPRewardDistributor = new TokenDistributor(currency);
        _DAORewardDistributor = new TokenDistributor(currency);
        _inviterRewardDistributor = new TokenDistributor(currency);

        uint256 _mineTotal = 39212 * 10 ** _decimals;

        _balances[address(_LPRewardDistributor)] = (_mineTotal * 80) / 100;
        emit Transfer(
            address(0),
            address(_LPRewardDistributor),
            (_mineTotal * 80) / 100
        );

        _balances[address(_DAORewardDistributor)] = (_mineTotal * 20) / 100;
        emit Transfer(
            address(0),
            address(_DAORewardDistributor),
            (_mineTotal * 20) / 100
        );

        uint256 _inviterTotal = 10000 * 10 ** _decimals;
        _balances[address(_inviterRewardDistributor)] = _inviterTotal;
        emit Transfer(
            address(0),
            address(_inviterRewardDistributor),
            _inviterTotal
        );

        _balances[ReceiveAddress] = _tTotal - _mineTotal - _inviterTotal;
        emit Transfer(
            address(0),
            ReceiveAddress,
            _tTotal - _mineTotal - _inviterTotal
        );

        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(_LPRewardDistributor)] = true;
        _feeWhiteList[address(_DAORewardDistributor)] = true;
        _feeWhiteList[address(_inviterRewardDistributor)] = true;

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        _addLpProvider(fundAddress);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external pure override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function setAntiSYNCEnable(bool s) public onlyOwner {
        antiSYNC = s;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == _mainPair && msg.sender == _mainPair && antiSYNC) {
            require(_balances[_mainPair] > 0, "!sync");
        }
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override {
        _approve(msg.sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _isAddLiquidity() internal view returns (bool isAdd) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();
        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();
        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    function _transfer(address from, address to, uint256 amount) private {
        // uint256 balance = balanceOf(from);
        require(balanceOf(from) >= amount);
        require(isReward(from) == 0);
        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(_mainPair).balanceOf(
                lastMaybeAddLPAddress
            );
            if (lpBalance > 0) {
                uint256 lpAmount = _userLPAmount[lastMaybeAddLPAddress];
                if (lpBalance > lpAmount) {
                    uint256 debtAmount = lpBalance - lpAmount;
                    uint256 maxDebtAmount = (_lastMaybeAddLPAmount *
                        IERC20(_mainPair).totalSupply()) / _balances[_mainPair];
                    if (debtAmount > maxDebtAmount) {
                        excludeLpProvider[lastMaybeAddLPAddress] = true;
                    } else {
                        _addLpProvider(lastMaybeAddLPAddress);
                        _userLPAmount[lastMaybeAddLPAddress] = lpBalance;
                    }
                }
            }
        }

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 4);
            uint256 balance = _balances[from];
            if (balance > remainAmount) {
                maxSellAmount = balance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool takeFee;
        bool isSell;
        bool isRemove;
        bool isAdd;

        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();
        } else if (_swapPairList[from]) {
            isRemove = _isRemoveLiquidity();
        }
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (enableOffTrade) {
                    require(startTradeBlock > 0 || isAdd);
                }
                if (
                    enableOffTrade &&
                    enableKillBlock &&
                    block.number < startTradeBlock + kb &&
                    !_swapPairList[to]
                ) {
                    _rewardList[to] = true;
                }
                if (_swapPairList[to]) {
                    if (!inSwap && !isAdd) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            uint256 swapFee = _buyFundFee +
                                _buyLPFee +
                                _buyLPDividendFee +
                                _sellFundFee +
                                _sellLPFee +
                                _sellLPDividendFee;
                            uint256 numTokensSellToFund = (amount * swapFee) /
                                5000;
                            if (numTokensSellToFund > contractTokenBalance) {
                                numTokensSellToFund = contractTokenBalance;
                            }
                            _swapTokenForFund(numTokensSellToFund, swapFee);
                        }
                    }
                }
                if (!isAdd && !isRemove) takeFee = true; // just swap fee
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        } else {
            if (address(0) == _inviter[to] && amount > 0 && from != to) {
                _maybeInvitor[to][from] = true;
            }
            if (address(0) == _inviter[from] && amount > 0 && from != to) {
                if (_maybeInvitor[from][to] && _binders[from].length == 0) {
                    _bindInvitor(from, to);
                }
            }
        }
        if (isRemove) {
            if (!_feeWhiteList[to]) {
                takeFee = true;
                uint256 liquidity = (amount *
                    ISwapPair(_mainPair).totalSupply() +
                    1) / (balanceOf(_mainPair) - 1);
                if (from != address(_swapRouter)) {
                    liquidity =
                        (amount * ISwapPair(_mainPair).totalSupply() + 1) /
                        (balanceOf(_mainPair) - amount - 1);
                }
                require(_userLPAmount[to] >= liquidity);
                _userLPAmount[to] -= liquidity;
            }
        }
        _tokenTransfer(from, to, amount, takeFee, isSell, isRemove);
        if (from != address(this)) {
            if (isSell) {
                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPAmount = amount;
            }
            if (!_feeWhiteList[from] && !isAdd) {
                _processThisLP(_rewardGas);
                if (_progressDividendLPBlock != block.number) {
                    _processMineLP(_rewardGas);
                }
                _processMineDAO();
                _processThisDividend();
            }
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool isRemove
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee + _sellLPFee + _sellLPDividendFee;
            } else {
                swapFee = _buyFundFee + _buyLPFee + _buyLPDividendFee;
            }

            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(sender, address(this), swapAmount);
            }

            uint256 burnAmount;
            if (!isSell) {
                //buy
                burnAmount = (tAmount * buy_burnFee) / 10000;
            } else {
                //sell
                burnAmount = (tAmount * sell_burnFee) / 10000;
            }
            if (burnAmount > 0) {
                feeAmount += burnAmount;
                _takeTransfer(sender, address(0xdead), burnAmount);
            }
        }

        if (isRemove && !_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            uint256 removeLiquidityFeeAmount;
            removeLiquidityFeeAmount = (tAmount * removeLiquidityFee) / 10000;
            if (removeLiquidityFeeAmount > 0) {
                feeAmount += removeLiquidityFeeAmount;
                _takeTransfer(sender, address(this), removeLiquidityFeeAmount);
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function _bindInvitor(address account, address invitor) private {
        if (
            invitor != address(0) &&
            invitor != account &&
            _inviter[account] == address(0)
        ) {
            uint256 size;
            assembly {
                size := extcodesize(invitor)
            }
            if (size > 0) {
                return;
            }
            _inviter[account] = invitor;
            _binders[invitor].push(account);
        }
    }

    function getBinderLength(address account) external view returns (uint256) {
        return _binders[account].length;
    }

    function _swapTokenForFund(
        uint256 tokenAmount,
        uint256 swapFee
    ) private lockTheSwap {
        if (swapFee == 0) {
            return;
        }
        swapFee += swapFee;
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 dividedFee = _buyLPDividendFee + _sellLPDividendFee;
        uint256 lpAmount = (tokenAmount * lpFee) / swapFee;
        uint256 fistBalance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = currency;
        fistBalance = address(this).balance;
        try
            _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount - lpAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
        }
        swapFee -= lpFee;
        uint256 lpFist;
        uint256 fundAmount;
        uint256 dividedAmount;
        fistBalance = address(this).balance - fistBalance;
        lpFist = (fistBalance * lpFee) / swapFee;
        dividedAmount = (fistBalance * 2 * dividedFee) / swapFee;
        fundAmount = fistBalance - lpFist - dividedAmount;
        if (fundAmount > 0) {
            _dividedAmount += fundAmount;
        }
        if (lpAmount > 0 && lpFist > 0) {
            // add the liquidity
            try
                _swapRouter.addLiquidityETH{value: lpFist}(
                    address(this),
                    lpAmount,
                    0,
                    0,
                    address(0xdead),
                    block.timestamp
                )
            {} catch {
                emit Failed_addLiquidityETH();
            }
        }
    }

    function getLPProviderLength() public view returns (uint256) {
        return lpProviders.length;
    }

    function getMineRewardByDays(uint256 _days) public pure returns (uint256) {
        if (_days < 60) {
            return 200 * 10 ** _decimals;
        } else if (_days < 150) {
            return 100 * 10 ** _decimals;
        } else if (_days < 240) {
            return 50 * 10 ** _decimals;
        } else if (_days < 2200) {
            return (73979 * 10 ** (_decimals)) / 10000;
        } else {
            return 0;
        }
    }

    receive() external payable {}

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {
                    size := extcodesize(adr)
                }
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    function _processMineLP(uint256 gas) private {
        if (_mineStartTime <= 0 ||
            block.timestamp < _mineStartTime ||
            _progressMineLPBlock + _progressMineLPBlockDebt > block.number
        ) {
            return;
        }
        uint totalPair = IERC20(_mainPair).totalSupply();
        if (0 == totalPair) {
            return;
        }
        address sender = address(_LPRewardDistributor);
        uint256 mineDays = (block.timestamp - _mineStartTime) / _mineRewardTimeDebt;
        if(_mineLPRewardDays > mineDays){
            return;
        }
        uint256 LPRewardCondition = getMineRewardByDays(_mineLPRewardDays) * 80 / 100;
        if (0 == LPRewardCondition || _balances[sender] < LPRewardCondition) {
            return;
        }
        address inviterSender = address(_inviterRewardDistributor);
        bool isInviterReward = _balances[inviterSender] > 0;
        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;
        uint256 surplus;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 shareholderCount = lpProviders.length;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (_currentMineLPIndex >= shareholderCount) {
                _currentMineLPIndex = 0;
                _mineLPRewardDays++;
                break;
            }
            shareHolder = lpProviders[_currentMineLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = IERC20(_mainPair).balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }
                if (
                    pairBalance >= minLPHoldAmount
                    //  && _lastMineLPRewardTimes[shareHolder] <= _mineLPRewardDays
                ) {
                    amount = (LPRewardCondition * pairBalance) / totalPair;
                    surplus = LPRewardCondition - _mineLPRewards[_mineLPRewardDays];
                    amount = surplus < amount ? surplus : amount;
                    if (amount > 0) {
                        _tokenTransfer(
                            sender,
                            shareHolder,
                            amount,
                            false,
                            false,
                            false
                        );
                        // _lastMineLPRewardTimes[shareHolder] = _mineLPRewardDays + 1;
                        _mineLPRewards[_mineLPRewardDays] += amount;
                        if (isInviterReward)
                            _distributeLPInviteReward(
                                shareHolder,
                                amount,
                                inviterSender
                            );
                    }
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentMineLPIndex++;
            iterations++;
        }
        _progressMineLPBlock = block.number;
    }

    function _distributeLPInviteReward(
        address current,
        uint256 reward,
        address sender
    ) private {
        address invitor;
        invitor = _inviter[current];
        if (address(0) == invitor) {
            return;
        }
        uint256 rreward = (reward * fristRate) / 100;
        _tokenTransfer(
            sender,
            invitor,
            rreward < _balances[sender] ? rreward : _balances[sender],
            false,
            false,
            false
        );
    }

    function _processMineDAO() private {
        if (_mineStartTime <= 0 || block.timestamp < _mineStartTime) {
            return;
        }
        uint totalPair = _totalDAOWeight;
        if (0 == totalPair) {
            return;
        }
        uint256 mineDays = (block.timestamp - _mineStartTime) /
            _mineRewardTimeDebt;
        mineDays = _mineDAORewardDays < mineDays
            ? _mineDAORewardDays
            : mineDays;
        uint256 DAORewardCondition = (getMineRewardByDays(mineDays) * 20) / 100;
        if (0 == DAORewardCondition || _mineDAORewardTimes[mineDays]) {
            return;
        }
        address sender = address(_DAORewardDistributor);
        if (_balances[sender] < DAORewardCondition) {
            return;
        }
        _mineDAORewardTimes[mineDays] = true;
        _mineDAORewardDays++;
        address shareHolder;
        uint256 pairBalance;
        uint256 amount;
        for (uint256 i; i < daoProviders.length; ) {
            shareHolder = daoProviders[i];
            pairBalance = _userDAOAmount[shareHolder];
            amount = (DAORewardCondition * pairBalance) / totalPair;
            if (amount > 0) {
                _tokenTransfer(
                    sender,
                    shareHolder,
                    amount,
                    false,
                    false,
                    false
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function _processThisDividend() private {
        uint totalPair = _totalDividendWeight;
        if (0 == totalPair) {
            return;
        }
        uint256 rewardCondition = dividendCondition;
        if (
            _dividedAmount < rewardCondition ||
            address(this).balance < rewardCondition
        ) {
            return;
        }
        address shareHolder;
        uint256 pairBalance;
        uint256 amount;
        for (uint256 i; i < dividedProviders.length; ) {
            shareHolder = dividedProviders[i];
            pairBalance = _userDividendAmount[shareHolder];
            amount = (rewardCondition * pairBalance) / totalPair;
            if (amount > 0) {
                shareHolder.call{value: amount}("");
                _dividedAmount = _dividedAmount - amount;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _processThisLP(uint256 gas) private {
        if (
            _progressDividendLPBlock + _progressDividendLPBlockDebt >
            block.number
        ) {
            return;
        }
        IERC20 mainpair = IERC20(_mainPair);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }
        uint256 rewardCondition = LPDividendCondition;
        if (
            address(this).balance < _dividedAmount ||
            address(this).balance - _dividedAmount < rewardCondition
        ) {
            return;
        }
        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 shareholderCount = lpProviders.length;
        while (gasUsed < gas && iterations < shareholderCount) {
            if (_currentDividendLPIndex >= shareholderCount) {
                _currentDividendLPIndex = 0;
            }
            shareHolder = lpProviders[_currentDividendLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = mainpair.balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }
                if (
                    pairBalance >= minLPHoldAmount
                ) {
                    amount = (rewardCondition * pairBalance) / totalPair;
                    if (amount > 0) {
                        shareHolder.call{value: amount}("");
                    }
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentDividendLPIndex++;
            iterations++;
        }
        _progressDividendLPBlock = block.number;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external {
        require(fundAddress == msg.sender);
        IERC20(token).transfer(to, amount);
    }

    function claimContractToken(
        address contractAddress,
        address token,
        uint256 amount
    ) external onlyOwner {
        // require(fundAddress == msg.sender);
        TokenDistributor(contractAddress).claimToken(
            token,
            fundAddress,
            amount
        );
    }

    function updateLPAmount(address account) external {
        require(_swapContract[msg.sender]);
        uint256 lpBalance = IERC20(_mainPair).balanceOf(account);
        if (lpBalance > 0) {
            _addLpProvider(account);
        }
        _userLPAmount[account] = lpBalance;
    }

    function setExcludeLPProvider(
        address addr,
        bool enable
    ) external {
        require(_owner == msg.sender || _swapContract[msg.sender]);
        excludeLpProvider[addr] = enable;
    }

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function setSwapContract(address account, bool enable) external onlyOwner {
        _swapContract[account] = enable;
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
        _addLpProvider(addr);
    }

    function launch() external onlyOwner {
        require(0 == startTradeBlock && _mineStartTime == 0);
        startTradeBlock = block.number;
        _mineStartTime = block.timestamp + 1 days;
    }

    function setFeeWhiteList(
        address[] calldata addr,
        bool enable
    ) external onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function multi_bclist(
        address[] calldata addresses,
        bool value
    ) external onlyOwner {
        require(enableRewardList);
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function setRemoveLiquidityFee(uint256 newValue) external onlyOwner {
        require(newValue <= 5000);
        removeLiquidityFee = newValue;
    }

    function setMinLPHoldAmount(uint256 amount) external onlyOwner {
        minLPHoldAmount = amount;
    }

    function setDividendCondition(uint256 _value) external onlyOwner{
        dividendCondition = _value;
    }

    function setLPDividendCondition(uint256 _value) external onlyOwner{
        LPDividendCondition = _value;
    }

    function addDAOProvider(
        address[] calldata addresses,
        uint256[] calldata weights
    ) external onlyOwner {
        require(addresses.length == weights.length && daoProviders.length == 0);
        address adr;
        uint256 weight;
        for (uint256 i; i < addresses.length; ) {
            adr = addresses[i];
            weight = weights[i];
            if (0 == daoProviderIndex[adr]) {
                if (0 == daoProviders.length || daoProviders[0] != adr) {
                    uint256 size;
                    assembly {
                        size := extcodesize(adr)
                    }
                    if (size > 0) {
                        return;
                    }
                    daoProviderIndex[adr] = daoProviders.length;
                    daoProviders.push(adr);
                    _userDAOAmount[adr] = weight;
                    _totalDAOWeight += weight;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function addDividendProvider(
        address[] calldata addresses,
        uint256[] calldata weights
    ) external onlyOwner {
        require(
            addresses.length == weights.length && dividedProviders.length == 0
        );
        address adr;
        uint256 weight;
        for (uint256 i; i < addresses.length; ) {
            adr = addresses[i];
            weight = weights[i];
            if (0 == dividedProviderIndex[adr]) {
                if (
                    0 == dividedProviders.length || dividedProviders[0] != adr
                ) {
                    uint256 size;
                    assembly {
                        size := extcodesize(adr)
                    }
                    if (size > 0) {
                        return;
                    }
                    dividedProviderIndex[adr] = dividedProviders.length;
                    dividedProviders.push(adr);
                    _userDividendAmount[adr] = weight;
                    _totalDividendWeight += weight;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
}

contract JDCC  is AbsToken {
    constructor() AbsToken(0x10ED43C718714eb63d5aA57B78B54704E256024E,0x0ee41E2e1b80f54695ffd047e55d8dFAd1b5F154,0x0ee41E2e1b80f54695ffd047e55d8dFAd1b5F154){

    }
}