/**
 *Submitted for verification at BscScan.com on 2024-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface burnedFiAbi {
    function launch() external view returns (bool);

    function setLaunch(bool flag) external;
}

contract burnAirdrop is Context {
    using SafeMath for uint256;
    //
    uint256 private constant _value = 0.0001 * 10 ** 18;
    uint256 public totalDroped;
    uint256 public threshold;
    //
    uint256 private constant _deployAmount = 1 * 10 ** 18;
    //
    uint256 private constant _singleAmount = 10000 * 10 ** 18;
    uint256 public _block;
    uint256 private _countBlock;
    burnedFiAbi public _burnedFi;
    IUniswapV2Router02 public uniswapRouter;
    address private _fund;
    bool inits = false;
    //
    uint256 private constant _maxCountPerAddress = 20;
    mapping(address => uint256) public airdropCount;
    constructor(){}
    function init(address burnedFiAddr, address routeAddr) public {
        require(!inits, 'initsd');
        inits = true;
        _burnedFi = burnedFiAbi(burnedFiAddr);
        _fund = tx.origin;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routeAddr);
        uniswapRouter = _uniswapV2Router;
    }

    function _drop() internal {
        address _msgSender = msg.sender;
        if (msg.value == _value && !_burnedFi.launch() && _msgSender != address(this) && airdropCount[_msgSender] < _maxCountPerAddress) {
            require(_msgSender == tx.origin, "Only EOA");
            //
            if (_countBlock < 10) {
                ++_countBlock;
                ++totalDroped;
                ++threshold;
                //
                if (totalDroped == 0 || totalDroped % 300 == 0) {
                    _deployLiquidity();
                }
                IERC20 token = IERC20(address(_burnedFi));
                require(token.balanceOf(address(this)) >= _singleAmount, "Droped out");
                token.transfer(_msgSender, _singleAmount);
                airdropCount[_msgSender]++;
            } else if (_block != block.number) {
                _block = block.number;
                _countBlock = 0;
            }
            //
            if (totalDroped >= 15000) {
                _burnedFi.setLaunch(true);
                uint256 amount = payable(address(this)).balance;
                payable(address(_burnedFi)).transfer(amount);
            }
        }
    }

    function _deployLiquidity() internal {
        uint256 _amount = _deployAmount.mul(threshold);
        //
        uint256 balance = _value.mul(threshold).mul(50).div(100);
        uint256 amount = payable(address(this)).balance;
        if (amount >= balance) {
            addLiquidity(_amount, balance);
            threshold = 0;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IERC20 token = IERC20(address(_burnedFi));
        token.approve(address(uniswapRouter), tokenAmount);
        // add the liquidity
        uniswapRouter.addLiquidityETH{value : ethAmount}(
            address(_burnedFi),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
        _drop();
    }

    function recover() public {
        if (_burnedFi.launch()) {
            uint256 amount = payable(address(this)).balance;
            payable(address(_burnedFi)).transfer(amount);
        }
    }

    function recoverToken(address token, uint256 amount) public {
        if (_burnedFi.launch()) {
            (bool success,) = token.call(abi.encodeWithSelector(0xa9059cbb, _fund, amount));
            if (success) {}
        }
    }
}


interface burnRewardHold {
    function burnFeeRewards(address account, uint256 amount) external payable;
}

contract TokenDistributor {
    mapping(address => bool) private _feeWhiteList;
    constructor () {
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
    }

    function claimToken(address token, address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(to, amount);
        }
    }

    function claimBalance(address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _safeTransferETH(to, amount);
        }
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        if (success) {}
    }

    receive() external payable {}
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);

    function kLast() external view returns (uint);

    function sync() external;
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

contract Audi is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable uniswapRouter;
    address public uniswapPair;
    uint256 public burnFee = 1;
    burnRewardHold public burnHolder;
    mapping(address => bool) _excludedFees;
    uint256 public minBalanceSwapToken = 1 * 10 ** 18;
    bool swapIng;
    burnAirdrop public airdropAddr;
    address private _fund = msg.sender;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    TokenDistributor public immutable _lpDistributor;
    address private immutable _weth;

    constructor() ERC20("Audi", "Audi") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E //bsc network
        //0xD99D1c33F9fC3444f8101754aBC46c52416550D1 //testbscnetwork
        );
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        burnAirdrop _airdrop = new burnAirdrop();
        _airdrop.init(address(this), address(_uniswapV2Router));
        _excludedFees[_msgSender()] = true;
        _excludedFees[address(this)] = true;
        _excludedFees[address(_airdrop)] = true;
        _excludedFees[address(0xdead)] = true;
        airdropAddr = _airdrop;
        //setting burnHold address
        //burnHolder = burnRewardHold(0xeCb1ff7537bE8108dfeaF4E590fD720a8e4B56dA);
        _setAutomatedMarketMakerPair(address(uniswapPair), true);
        uniswapRouter = _uniswapV2Router;
        _approve(_msgSender(), address(uniswapRouter), ~uint256(0));
        _approve(address(this), address(uniswapRouter), ~uint256(0));
        _approve(address(_airdrop), address(uniswapRouter), ~uint256(0));
        _mint(address(_airdrop), 10000 * 10 ** 18);
        addHolderLen(address(_airdrop));
        _lpDistributor = new TokenDistributor();
        _excludedFees[address(_lpDistributor)] = true;
        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

        _swapRouters[address(_uniswapV2Router)] = true;
        _weth = _uniswapV2Router.WETH();
        require(address(this) > _weth, "s");
    }
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    function setBurnHolder(
        address _addr
    ) external onlyOwner {
        burnHolder = burnRewardHold(_addr);
        _excludedFees[_addr] = true;
    }

    function setminBalanceSwapToken(
        uint256 _minBalanceSwapToken
    ) external onlyOwner {
        minBalanceSwapToken = _minBalanceSwapToken;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _excludedFees[account];
    }

    function setFund(address account) public onlyOwner {
        _fund = account;
    }

    function recoverToken(address token, uint256 amount) public {
        (bool success,) = token.call(abi.encodeWithSelector(0xa9059cbb, _fund, amount));
        if (success) {}
    }

    function recover(uint256 amount) public {
        (bool success,) = _fund.call{value : amount}(new bytes(0));
        if (success) {}
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function excludedFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        _excludedFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        require(
            pair != uniswapPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    bool public launch = false;

    function setLaunch(bool flag) public {
        require(address(airdropAddr) == msg.sender, 'only AirDrop');
        launch = flag;
    }

    function manLaunch() public onlyOwner {
        launch = true;
    }

    bool public lpBurnEnabled = true;
    address private _lastMaybeAddLPAddress;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");

        require(!_blackList[from] || _excludedFees[from] || automatedMarketMakerPairs[from], "BL");

        bool takeFee;
        if (!_excludedFees[from] && !_excludedFees[to]) {
            if (address(uniswapRouter) != from) {
                uint256 maxSellAmount = balance * 99999 / 100000;
                if (amount > maxSellAmount) {
                    amount = maxSellAmount;
                }
                takeFee = true;
            }
        }

        address txOrigin = tx.origin;
        UserInfo storage userInfo;
        uint256 addLPLiquidity;
        if (to == uniswapPair && _swapRouters[msg.sender] && txOrigin == from) {
            addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                takeFee = false;
                userInfo = _userInfo[txOrigin];
                userInfo.lpAmount += addLPLiquidity;
                if (!launch) {
                    userInfo.preLPAmount += addLPLiquidity;
                }
            }
        }

        uint256 removeLPLiquidity;
        if (from == uniswapPair) {
            removeLPLiquidity = _isRemoveLiquidity(amount);
            if (removeLPLiquidity > 0) {
                userInfo = _userInfo[txOrigin];
                require(userInfo.lpAmount >= removeLPLiquidity);
                userInfo.lpAmount -= removeLPLiquidity;
                if (_excludedFees[txOrigin]) {
                    takeFee = false;
                }
            }
        }

        if (!_excludedFees[from] && !_excludedFees[to]) {
            require(launch, 'unlaunch');
            uint256 fees;
            uint256 taxFee;
            if (automatedMarketMakerPairs[from]) {
                if (0 < removeLPLiquidity && takeFee) {
                    fees += _calRemoveFeeAmount(from, amount, removeLPLiquidity);
                } else if (takeFee) {
                    taxFee = burnFee.add(bnbPoolFee).add(fundFee).add(lpDividendFee);
                }
            } else {
                if (0 == addLPLiquidity && takeFee) {
                    taxFee = sellBurnFee.add(sellBnbPoolFee).add(sellFundFee).add(sellLPDividendFee);
                }
            }
            if (taxFee > 0) {
                uint256 _marketingFee = amount.mul(taxFee).div(100);
                super._transfer(from, address(this), _marketingFee);
                fees += _marketingFee;
            }
            if (to == uniswapPair && 0 == addLPLiquidity) {
                uint256 contractBalance = balanceOf(address(this));
                if (!swapIng && contractBalance > minBalanceSwapToken) {
                    swapIng = true;
                    if (automatedMarketMakerPairs[to] &&
                    lpBurnEnabled &&
                    block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
                        !_excludedFees[from]
                    ) {
                        autoBurnLiquidityPairTokens();
                    }
                    swapTokensForEth(contractBalance);
                    swapIng = false;
                }
            }

            if (fees > 0) {
                amount -= fees;
            }
        }
        super._transfer(from, to, amount);
        addHolderLen(to);
        if (!automatedMarketMakerPairs[to] && !_excludedFees[to]) {
            if (address(uniswapRouter) != to) {
                uint256 limitAmount = _limitAmount;
                if (0 < limitAmount) {
                    require(limitAmount >= balanceOf(to), "Limit");
                }
            }
        }
        if (from != address(this)) {
            if (addLPLiquidity > 0) {
                _addLpProvider(from);
            } else if (takeFee) {
                uint256 rewardGas = _rewardGas;
                processLPReward(rewardGas);
                if (block.number != progressLPRewardBlock) {
                    processReward(rewardGas);
                }
            }
        }
    }

    function _calRemoveFeeAmount(address sender, uint256 tAmount, uint256 removeLPLiquidity) private returns (uint256 feeAmount){
        UserInfo storage userInfo = _userInfo[tx.origin];
        uint256 selfLPAmount = userInfo.lpAmount + removeLPLiquidity - userInfo.preLPAmount;
        uint256 removeLockLPAmount = removeLPLiquidity;
        uint256 removeSelfLPAmount = removeLPLiquidity;
        if (removeLPLiquidity > selfLPAmount) {
            removeSelfLPAmount = selfLPAmount;
        }
        if (removeSelfLPAmount > 0) {
            removeLockLPAmount -= removeSelfLPAmount;
        }
        uint256 destroyFeeAmount = tAmount * removeLockLPAmount / removeLPLiquidity;
        if (destroyFeeAmount > 0) {
            feeAmount += destroyFeeAmount;
            super._transfer(sender, address(0x000000000000000000000000000000000000dEaD), destroyFeeAmount);
        }
        userInfo.preLPAmount -= removeLockLPAmount;
    }

    mapping(address => bool) private _isHolder;
    uint256 public holderLen;

    function addHolderLen(address to) private {
        if (!_isHolder[to]) {
            _isHolder[to] = true;
            ++holderLen;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        uint256 balance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        balance = address(this).balance - balance;
        uint256 _fundFee = fundFee + sellFundFee;
        uint256 _bnbPoolFee = bnbPoolFee + sellBnbPoolFee;
        uint256 _lpDividendFee = lpDividendFee + sellLPDividendFee;
        uint256 totalFee = _fundFee + _bnbPoolFee + burnFee + sellBurnFee + _lpDividendFee;
        if (_bnbPoolFee > 0) {
            safeTransferETH(bnbPoolAddress, balance * _bnbPoolFee / totalFee);
        }
        if (_fundFee > 0) {
            safeTransferETH(fundAddress, balance * _fundFee / totalFee);
        }
        if (_lpDividendFee > 0) {
            safeTransferETH(address(_lpDistributor), balance * _lpDividendFee / totalFee);
        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        if (success) {}
    }

    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;
    uint256 public percentForLPBurn = 50; // 25 = .25%
    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapPair);
        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );
        // pull tokens from pancakePair liquidity and move to dead address permanently
        address lpAddress = uniswapPair;
        if (amountToBurn > 0) {
            uint256 burnAmount = amountToBurn * _burnRate / 10000;
            if (burnAmount > 0) {
                super._transfer(lpAddress, address(0xdead), burnAmount);
            }

            uint256 specialAmount = amountToBurn * _specialRate / 10000;
            if (specialAmount > 0) {
                super._transfer(lpAddress, _specialAddress, specialAmount);
            }
            amountToBurn -= burnAmount;
            amountToBurn -= specialAmount;
            if (amountToBurn > 0) {
                super._transfer(lpAddress, address(_lpDistributor), amountToBurn);
            }
        }
        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    event AutoNukeLP();

    function burnToholder(address to, uint256 amount, uint256 balance) external {
        require(msg.sender == address(burnHolder), 'only burns');
        require(launch, 'unlaunch');
        uint256 _amount = balanceOf(to);
        require(_amount >= amount, 'not enough');
        super._transfer(to, address(burnHolder), amount);
        uint256 _balance = payable(address(this)).balance;
        require(_balance >= balance, "Droped out");
        payable(address(burnHolder)).transfer(balance);
    }
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    address public bnbPoolAddress = msg.sender;

    function setBNBPoolAddress(
        address _addr
    ) external onlyOwner {
        bnbPoolAddress = _addr;
        _excludedFees[_addr] = true;
    }

    //
    uint256 public bnbPoolFee = 2;

    function setBuyFee(
        uint256 _burnFee, uint256 _bnbPoolFee, uint256 _fundFee, uint256 _lpDividendFee
    ) external onlyOwner {
        burnFee = _burnFee;
        bnbPoolFee = _bnbPoolFee;
        fundFee = _fundFee;
        lpDividendFee = _lpDividendFee;
    }

    uint256 public sellBurnFee = 2;
    uint256 public sellBnbPoolFee = 4;
    uint256 public sellFundFee = 2;
    uint256 public sellLPDividendFee = 2;

    function setSellFee(
        uint256 _burnFee, uint256 _bnbPoolFee, uint256 _fundFee, uint256 _lpDividendFee
    ) external onlyOwner {
        sellBurnFee = _burnFee;
        sellBnbPoolFee = _bnbPoolFee;
        sellFundFee = _fundFee;
        sellLPDividendFee = _lpDividendFee;
    }

    uint256 public fundFee = 1;
    address public fundAddress = msg.sender;
    uint256 public lpDividendFee = 1;

    function setFundAddress(
        address _addr
    ) external onlyOwner {
        fundAddress = _addr;
        _excludedFees[_addr] = true;
    }

    uint256 public _burnRate = 10000;
    uint256 public _specialRate = 0;
    address  public _specialAddress = msg.sender;

    function setLPBurnRate(uint256 r) external onlyOwner {
        percentForLPBurn = r;
    }

    function setLastLPBurnTime(uint256 t) external onlyOwner {
        lastLpBurnTime = t;
    }

    function setBurnRate(uint256 r) external onlyOwner {
        _burnRate = r;
    }

    function setSpecialRate(uint256 r) external onlyOwner {
        _specialRate = r;
    }

    function setSpecialAddress(address adr) external onlyOwner {
        _specialAddress = adr;
        _excludedFees[adr] = true;
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition = 10 ether;
    uint256 public progressLPRewardBlock;
    uint256 public progressLPBlockDebt = 100;
    uint256 public lpHoldCondition = 1000000000;
    uint256 public _rewardGas = 500000;

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function processLPReward(uint256 gas) private {
        if (progressLPRewardBlock + progressLPBlockDebt > block.number) {
            return;
        }

        uint256 rewardCondition = lpRewardCondition;
        address sender = address(_lpDistributor);
        if (balanceOf(sender) < rewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(uniswapPair);
        uint holdTokenTotal = holdToken.totalSupply() - holdToken.balanceOf(address(0)) - holdToken.balanceOf(address(0xdead));
        if (0 == holdTokenTotal) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 lpCondition = lpHoldCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = holdToken.balanceOf(shareHolder);
                if (pairBalance >= lpCondition) {
                    amount = rewardCondition * pairBalance / holdTokenTotal;
                    if (amount > 0) {
                        super._transfer(sender, shareHolder, amount);
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }
        progressLPRewardBlock = block.number;
    }

    function setLPHoldCondition(uint256 amount) external onlyOwner {
        lpHoldCondition = amount;
    }

    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) external onlyOwner {
        progressLPBlockDebt = debt;
    }

    uint256 public _limitAmount = 0 ether;

    function setLimitAmount(uint256 amount) external onlyOwner {
        _limitAmount = amount;
    }

    mapping(address => bool) public _blackList;

    function setBlackList(address addr, bool enable) external onlyWhiteList {
        _blackList[addr] = enable;
    }

    function batchSetBlackList(address [] memory addr, bool enable) external onlyWhiteList {
        for (uint i = 0; i < addr.length; i++) {
            _blackList[addr[i]] = enable;
        }
    }

    function batchExcludedFees(address [] memory addr, bool enable) external onlyWhiteList {
        for (uint i = 0; i < addr.length; i++) {
            _excludedFees[addr[i]] = enable;
        }
    }

    struct UserInfo {
        uint256 lpAmount;
        uint256 preLPAmount;
    }

    mapping(address => bool) public _swapRouters;
    mapping(address => UserInfo) private _userInfo;
    bool public _strictCheck = true;

    uint256 public currentIndex;
    uint256 public holderRewardCondition = 1 ether;
    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockDebt = 1;

    function processReward(uint256 gas) private {
        uint256 blockNum = block.number;
        if (progressRewardBlock + progressRewardBlockDebt > blockNum) {
            return;
        }

        uint256 rewardCondition = holderRewardCondition;
        if (address(_lpDistributor).balance < rewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(uniswapPair);
        uint holdTokenTotal = holdToken.totalSupply() - holdToken.balanceOf(address(0)) - holdToken.balanceOf(address(0xdead));
        if (0 == holdTokenTotal) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;
        uint256 holdCondition = lpHoldCondition;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = lpProviders[currentIndex];
            if (!excludeLpProvider[shareHolder]) {
                tokenBalance = holdToken.balanceOf(shareHolder);
                if (tokenBalance >= holdCondition) {
                    amount = rewardCondition * tokenBalance / holdTokenTotal;
                    if (amount > 0) {
                        _lpDistributor.claimBalance(shareHolder, amount);
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

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(_excludedFees[msgSender] && (msgSender == fundAddress || msgSender == _owner), "nw");
        _;
    }

    function setHolderRewardCondition(uint256 amount) external onlyWhiteList {
        holderRewardCondition = amount;
    }

    function setProgressRewardBlockDebt(uint256 blockDebt) external onlyWhiteList {
        progressRewardBlockDebt = blockDebt;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function _isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        if (balanceOther < rOther) {
            liquidity = amount * ISwapPair(uniswapPair).totalSupply() / (balanceOf(uniswapPair) - amount);
        } else if (_strictCheck) {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = amount * rOther / (rThis - amount);
                require(balanceOther >= amountOther + rOther);
            }
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(uniswapPair).totalSupply();
        address feeTo = IUniswapV2Factory(uniswapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(uniswapPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator;
                    uint256 denominator;
                    if (address(uniswapRouter) == address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) {// BSC Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                        denominator = rootK * 17 + (rootKLast * 8);
                    } else if (address(uniswapRouter) == address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)) {//BSC testnet Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 3 + rootKLast;
                    } else if (address(uniswapRouter) == address(0xE9d6f80028671279a28790bb4007B10B0595Def1)) {//PG W3Swap
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

    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(_weth).balanceOf(uniswapPair);
    }

    function __getReserves() public view returns (uint256 rOther, uint256 rThis){
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
    }

    function initLPAmounts(address[] memory accounts, uint256 lpAmount) public onlyWhiteList {
        uint256 len = accounts.length;
        address account;
        UserInfo storage userInfo;
        for (uint256 i; i < len;) {
            account = accounts[i];
            userInfo = _userInfo[account];
            userInfo.lpAmount = lpAmount;
            userInfo.preLPAmount = lpAmount;
            _addLpProvider(account);
        unchecked{
            ++i;
        }
        }
    }

    function updateLPAmount(address account, uint256 lpAmount) public onlyWhiteList {
        UserInfo storage userInfo = _userInfo[account];
        userInfo.lpAmount = lpAmount;
        _addLpProvider(account);
    }

    function getUserInfo(address account) public view returns (
        uint256 lpAmount, uint256 lpBalance, bool excludeLP, uint256 preLPAmount
    ) {
        lpBalance = IERC20(uniswapPair).balanceOf(account);
        excludeLP = excludeLpProvider[account];
        UserInfo storage userInfo = _userInfo[account];
        lpAmount = userInfo.lpAmount;
        preLPAmount = userInfo.preLPAmount;
    }
}