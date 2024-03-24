/**
 *Submitted for verification at BscScan.com on 2024-02-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{ value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value : weiValue}(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function feeTo() external view returns (address);

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);

    function kLast() external view returns (uint);

    function sync() external;
}

contract LTT is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    struct UserInfo {
        uint256 lpAmount;
        bool preLP;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address payable public marketingWalletAddress;
    address public deadAddress = address(0);//0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    uint256 public _buyLiquidityFee = 100;
    uint256 public _buyMarketingFee = 200;
    uint256 public _buyDestroyFee = 100;

    uint256 public _sellLiquidityFee = 100;
    uint256 public _sellMarketingFee = 200;
    uint256 public _sellDestroyFee = 100;

    uint256 public _transferFee = 500;

    uint256 public _liquidityShare = 200;
    uint256 public _marketingShare = 400;
    uint256 public _dividendShare = 200;
    uint256 public _totalDistributionShares = 800;

    uint256 public _totalTaxIfBuying = 500;
    uint256 public _totalTaxIfSelling = 500;

    uint256 public _tFeeTotal;
    uint256 private _totalSupply;
    uint256 public _maxTxAmount;
    uint256 private _minimumTokensBeforeSwap = 0;
    address private receiveAddress;
    address private devAddress;
    address public immutable _weth;


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    mapping(address => bool) public _swapRouters;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public _strictCheck = true;
    mapping(address => UserInfo) private _userInfo;
    uint256 public startTradeBlock;
    
    bool private startTx;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(msgSender == devAddress || msgSender == _owner, "nw");
        _;
    }

    constructor (
    ) payable {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(block.chainid == 56? 
            0x10ED43C718714eb63d5aA57B78B54704E256024E : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        _swapRouters[address(_uniswapV2Router)] = true;
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _weth = _uniswapV2Router.WETH();
        _name = "LTT";
        _symbol = "LTT";
        _decimals = 18;
        require(address(this) > _weth,"creat error");
        _owner = msg.sender;//wzb
        receiveAddress = _owner;

        _totalSupply = 50  * 10 ** _decimals;
        _maxTxAmount = 0;
        _minimumTokensBeforeSwap = 10 * 10**_decimals;
        marketingWalletAddress = payable(_owner);
        devAddress = msg.sender;
        uniswapV2Router = _uniswapV2Router;
        holderRewardCondition = 1 * 10 ** 17;
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);

        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[devAddress] = true;
        isExcludedFromFee[address(this)] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[deadAddress] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(_uniswapV2Router)] = true;

        isMarketPair[address(uniswapPair)] = true;
        _balances[_owner] = 200000 * 10 ** _decimals;
        emit Transfer(address(0), _owner, 200000 * 10 ** _decimals);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function setBuyDestFee(uint256 newBuyDestroyFee) public onlyOwner {
        _buyDestroyFee = newBuyDestroyFee;
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDestroyFee);
    }

    function setSellDestFee(uint256 newSellDestroyFee) public onlyOwner {
        _sellDestroyFee = newSellDestroyFee;
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellDestroyFee);
    }

    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDestroyFee);
    }


    function setSelTaxes(uint256 newLiquidityTax, uint256 newMarketingTax) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellDestroyFee);
    }

    function setTransferFee(uint256 newTransfer) external onlyOwner(){
        _transferFee = newTransfer;
    }

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare,uint256 newDividend) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _dividendShare = newDividend;
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_dividendShare);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setDevAddress(address addr) external onlyWhiteList {
        devAddress = addr;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        _minimumTokensBeforeSwap = newLimit;
    }


    function setMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWalletAddress = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    bool public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 1 minutes;//3600 seconds; // 
    uint256 public lastLpBurnTime;
    uint256 public percentForLPBurn = 100; // 100 = 1%


    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
        _startTradeTime = block.timestamp;
        lpBurnEnabled = true;
        lastLpBurnTime = block.timestamp;
        startTx = true;
    }


    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = excluded;
        }
    }


    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    event AutoNukeLP();
    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;
        // get balance of liquidity pair
        uint256 liquidityPairBalance = balanceOf(uniswapPair);
        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(10000);
        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            _basicTransfer(uniswapPair, deadAddress, amountToBurn);
        }
        //sync price since this is not in a swap transaction!
        ISwapPair pair = ISwapPair(uniswapPair);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }


     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    address public _lastMaybeAddLPAddress;

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "BNE");

        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
            if(isMarketPair[sender] || isMarketPair[recipient]){
                require(startTx, "not start");
            }
        }

        if(inSwapAndLiquify)
        {
            return _basicTransfer(sender, recipient, amount);
        }
        else
        {
            if (lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency 
            && !isExcludedFromFee[sender] && !isMarketPair[sender]) {
                autoBurnLiquidityPairTokens();
            }


            bool isAddLP;
            bool isRemoveLP;
            UserInfo storage userInfo;

            uint256 addLPLiquidity;
            if (isMarketPair[recipient] && _swapRouters[msg.sender]) {
                addLPLiquidity = _isAddLiquidity(amount);
                if (addLPLiquidity > 0) {
                    userInfo = _userInfo[sender];
                    userInfo.lpAmount += addLPLiquidity;
                    isAddLP = true;
                    userInfo.preLP = true;
                }
            }
            
            uint256 removeLPLiquidity;

            if (isMarketPair[sender] && !_swapRouters[recipient]) {
                if (_strictCheck) {
                    removeLPLiquidity = _strictCheckBuy(amount);
                } else {
                    removeLPLiquidity = _isRemoveLiquidity(amount);
                }
            } else if (_swapRouters[sender]) {
                removeLPLiquidity = _isRemoveLiquidityETH(amount);
            }

            bool takeFe = true;
            if (isAddLP) {
                takeFe = false;
            }
            if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]){
                takeFe = false;
            }

            takeFee(sender, recipient, amount, takeFe, isRemoveLP);

            // if (sender != address(this)) {
            //     if (isMarketPair[recipient]) {
            //         _lastMaybeAddLPAddress = sender;
            //     }
            //     if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
            //         uint256 rewardGas = _rewardGas;
            //         processReward(rewardGas);
            //     }
            // }

            return true;
        }
    }

    mapping(address => bool) public buyUser;

    uint256 public limitAmount;
    function setLimitAmount(uint256 _limitAmount)public onlyOwner{
        limitAmount = _limitAmount;
    }

    function takeFee(address sender, address recipient, uint256 amount,bool takeFe,bool isRemoveLP) internal {

        uint256 feeAmount = 0;
        uint256 swapFeeAmount;
        bool isSell;
        if (takeFe) {
            if (isRemoveLP) {
                //_basicTransfer(sender, deadAddress, feeAmount);
            } else if(isMarketPair[sender]) {
                // buy
                swapFeeAmount = amount.mul(_totalTaxIfBuying).div(10000);

            } else if(isMarketPair[recipient]) {
                isSell = true;
                // sell
                swapFeeAmount = amount.mul(_totalTaxIfSelling).div(10000);
            }else{
                // transfer
                swapFeeAmount = amount;//.mul(_transferFee).div(10000);
            }
            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _basicTransfer(sender, address(this), swapFeeAmount);
            }

            // if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled && isSell)
            // {
            //     if(swapAndLiquifyByLimitOnly)
            //         contractTokenBalance = _minimumTokensBeforeSwap;
            //     swapAndLiquify(contractTokenBalance);
            // }
        }

        _basicTransfer(sender, recipient, amount - feeAmount);
    }



    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        // uint256 newBalance =  address(this).balance;
        // uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        // uint256 tokensForSwap = tAmount.sub(tokensForLP);
        // swapTokensForEth(tokensForSwap);
        // uint256 amountReceived = address(this).balance - newBalance;

        // uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));

        // uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        // uint256 amountDividend = amountReceived.mul(_dividendShare).div(totalBNBFee);
        // uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountDividend);

        // if(amountBNBMarketing > 0)
        //     transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        // if(amountBNBLiquidity > 0 && tokensForLP > 0)
        //     addLiquidity(tokensForLP, amountBNBLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            receiveAddress,
            block.timestamp
        );
    }

    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;

    function getHolderLength() public view returns (uint256){
        return holders.length;
    }

    function addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public holderCondition = 1000000000000; // 0.000001
    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockDebt = 1;

    function processReward(uint256 gas) private {
        uint256 blockNum = block.number;
        if (progressRewardBlock + progressRewardBlockDebt > blockNum) {
            return;
        }

        uint256 balance = address(this).balance;
        if (balance < holderRewardCondition) {
            return;
        }
        balance = holderRewardCondition;

        IERC20 holdToken = IERC20(uniswapPair);
        uint holdTokenTotal = holdToken.totalSupply();
        if (holdTokenTotal == 0) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = holderCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            if (!excludeHolder[shareHolder]) {
                tokenBalance = holdToken.balanceOf(shareHolder);
                if (tokenBalance >= holdCondition) {
                    amount = balance * tokenBalance / holdTokenTotal;
                    if (amount > 0) {
                        transferToAddressETH(payable(shareHolder), amount);
                    }
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = blockNum;
    }

    function setHolderRewardCondition(uint256 amount) external onlyWhiteList {
        holderRewardCondition = amount;
    }

    uint256 public _rewardGas = 500000;

    function setRewardGas(uint256 rewardGas) external onlyWhiteList {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        //isAddLP
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(uniswapPair).totalSupply();
        address feeTo = IUniswapV2Factory(uniswapV2Router.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(uniswapPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply * (rootK - rootKLast) * 3;
                    uint256 denominator = rootK * 5 + rootKLast;
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            if (amount0 > 0) {
                liquidity = Math.sqrt(amount0 * amount) - 1000;
            }
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        ISwapPair mainPair = ISwapPair(uniswapPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _weth;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(uniswapPair);
    }

    function _isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, , uint256 balanceOther) = _getReserves();
        //isRemoveLP
        if (balanceOther <= rOther) {
            liquidity = amount * ISwapPair(uniswapPair).totalSupply() / (balanceOf(uniswapPair) - amount);
        }
    }

    function _strictCheckBuy(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        //isRemoveLP
        if (balanceOther < rOther) {
            liquidity = (amount * ISwapPair(uniswapPair).totalSupply()) /
            (_balances[uniswapPair] - amount);
        } else {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = amount * rOther / (rThis - amount);
                //strictCheckBuy
                require(balanceOther >= amountOther + rOther);
            }
        }
    }

    function _isRemoveLiquidityETH(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, , uint256 balanceOther) = _getReserves();
        //isRemoveLP
        if (balanceOther <= rOther) {
            liquidity = amount * ISwapPair(uniswapPair).totalSupply() / balanceOf(uniswapPair);
        }
    }

    uint256 public _removeLPFee = 0;
    uint256 public _removeLPFeeDuration = 7 days;
    uint256 public _startTradeTime;

    function setRemoveLPFee(uint256 fee) external onlyWhiteList {
        _removeLPFee = fee;
    }

    function setRemoveLPFeeDuration(uint256 d) external onlyWhiteList {
        _removeLPFeeDuration = d;
    }

    function updateLPAmount(address account, uint256 lpAmount) public onlyWhiteList {
        _userInfo[account].lpAmount = lpAmount;
    }

    function getUserInfo(address account) public view returns (
        uint256 lpAmount, uint256 lpBalance, bool excludeLP, bool preLP
    ) {
        lpAmount = _userInfo[account].lpAmount;
        lpBalance = IERC20(uniswapPair).balanceOf(account);
        excludeLP = excludeHolder[account];
        UserInfo storage userInfo = _userInfo[account];
        preLP = userInfo.preLP;
    }

    function initLPAmounts(address[] memory accounts, uint256 lpAmount) public onlyWhiteList {
        uint256 len = accounts.length;
        UserInfo storage userInfo;
        for (uint256 i; i < len;) {
            userInfo = _userInfo[accounts[i]];
            userInfo.lpAmount = lpAmount;
            userInfo.preLP = true;
            addHolder(accounts[i]);
        unchecked{
            ++i;
        }
        }
    }


}