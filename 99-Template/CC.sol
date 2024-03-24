/**
 *https://bscscan.com/token/0xddb341e88bb2dd7cb56e3c62991c5ad3911518cc
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

abstract contract Ownable {
    address private _owner = 0xDb3C906B908f61D0373fFF8f80Cd1FED9C731F35;
   

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        // address msgSender =  msg.sender;
        // _owner = msgSender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    // function transferOwnership(address newOwner) public virtual onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IUniswapV2Pair {
        function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
        function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function sync() external;
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    

}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}



contract  CC is IERC20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _updated;
    string public _name ;
    string public _symbol ;
    uint8 public _decimals ;
    uint256 private _tTotal ;
    address public _uniswapV2Pair;
    address public _marketAddr ;
    address public constant  _token = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public _startTimeForSwap;
    uint256 public constant _intervalSecondsForSwap =  90 days;
    uint8 public _enabOwnerAddLiq;
    IUniswapV2Router02 public constant  _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 public _currentIndex; 
    mapping(address => bool) public _isDividendExempt; 
    uint256 public constant _minPeriod = 1 days;
    uint256 public _buyBurnFee = 1500;
    uint256 public _buyMarketFee = 1000;
    uint256 public _sellBurnFee = 1500;
    uint256 public _sellMarketFee = 1000;
    uint256 public constant _lpTime = 3 hours;
    uint256 public _time = 4 hours; 
    uint public ddd = 200000e18;
    uint public lastClaimTime;
    uint public everyDivi = 35;

    mapping(uint =>uint  ) public theDayMint;
 
    mapping (address=>uint) public addLPTime;
    mapping (address => uint256) public pairAmount;

    constructor(){
            address admin;
            admin = 0xDb3C906B908f61D0373fFF8f80Cd1FED9C731F35;
            _marketAddr = 0x7164FDe412CAa3bc47Ec93337dfD001Fc1d9de0f;
            // transferOwnership(admin);  
            _enabOwnerAddLiq = 1;
            _name = "CC";
            _symbol = "CC";
            _decimals= uint8(18);

            if(block.chainid==97){
                admin = msg.sender;
            }

            _tTotal = 550000000 * (10**uint256(_decimals));
            _tOwned[admin] =  45000000* (10**uint256(_decimals));
            _tOwned[address(this)] = 505000000* (10**uint256(_decimals));
            //exclude owner and this contract from fee
            _isDividendExempt[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE]=true;//The pink lock address
            _isDividendExempt[address(this)] = true;
            _isDividendExempt[address(0)] = true;
            _isDividendExempt[address(0xdead)] = true;
            emit Transfer(address(0), admin, _tOwned[admin]);
            emit Transfer(address(0), address(this), _tOwned[address(this)]);
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }
     
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(_startTimeForSwap == 0 && msg.sender == address(_uniswapV2Router) ) {//Our first step is to add liquidity
            if(_enabOwnerAddLiq == 1){require( sender== owner(),"not owner");} //just owner can be top addLiq
            _startTimeForSwap =block.timestamp;
            _uniswapV2Pair = recipient;
        } 
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public _isFinallyFee ;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint amount1 = amount;
        if(_startTimeForSwap != 0 && !_isFinallyFee){
            if( block.timestamp > _startTimeForSwap + _intervalSecondsForSwap ) {
                _buyMarketFee = 0;
                _buyBurnFee = 30;
                _sellMarketFee = 0;
                _sellBurnFee = 30;
                _isFinallyFee = true;
            } else if( block.timestamp  > _startTimeForSwap + 48 hours) {
                _buyMarketFee = 0;
                _buyBurnFee = 200;
                _sellMarketFee = 0;
                _sellBurnFee = 200;
            }else if(block.timestamp > _startTimeForSwap + 30 minutes) {
                _buyMarketFee = 100;
                _buyBurnFee = 200;
                _sellMarketFee = 100;
                _sellBurnFee = 200;
            }
        }
        
        if(!(to==_uniswapV2Pair&&_isAddLiquidity()) && (from != owner())){
           amount = burnToken(from, to, amount);
        }
        _basicTransfer(from, to, amount);

        if(to==_uniswapV2Pair&&_isAddLiquidity()){
            if(!_isDividendExempt[from]) {
                uint256 addUSDTAmount = getAddLiquidity();
                uint256 liquidity = getPairAmount();
                pairAmount[from] += liquidity;
                if(25000e18>=addUSDTAmount  && addUSDTAmount >= 25e18 ) { 
                    //Reinvestment requires increased cooling time
                    addLPTime[from] = block.timestamp;
                    setShare(from);
                }else{
                    revert("Not Mint");
                }   
            }
        }else if(from==_uniswapV2Pair&&_isRemoveLiquidity()){ 
            //As long as there is a move to remove liquidity, no dividends will be distributed
            uint liquidit111 = getRemoveLP(amount1);
            if(pairAmount[to]>= liquidit111*99/100){ 
                if(  pairAmount[to]> liquidit111){
                    pairAmount[to] = pairAmount[to]-liquidit111;
                }else{
                    pairAmount[to] = 0;
                }
            }else{
                _basicTransfer( to,address(0xdead), amount1*20/100);
                pairAmount[to] = 0;
            }
            addLPTime[to] = 0;
            _shareholders.remove(to);
        }
        uint lpBal =  getMintNum();
        if(lpBal > 0&& from !=address(this)&&balanceOf(address(this))>0 &&getLpTotal()>0 ) {
            process() ;
        }
    }

    function getAddLiquidity() internal view returns (uint256 addUSDTAmount){
        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        addUSDTAmount = bal - r;
    }



    function getPairAmount() internal view returns (uint256 liquidity) {
        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        (uint112 _reserve0, uint112 _reserve1,) = mainPair.getReserves(); // gas savings
        address token0 = mainPair.token0();
        address token1 = mainPair.token1();

        uint balance0 = IERC20(token0).balanceOf(address(mainPair));
        uint balance1 = IERC20(token1).balanceOf(address(mainPair));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);


        uint _totalSupply = mainPair.totalSupply(); 
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(10**3);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
    }


    function burnToken(address from, address to, uint256 amount) private returns (uint256){
     
       uint256 _burnAmount;
       uint256 _marketAmount;
       if(from == _uniswapV2Pair) { // buy
         _burnAmount = amount.mul(_buyBurnFee).div(10000);
         _marketAmount = amount.mul(_buyMarketFee).div(10000);
       }
       if(to == _uniswapV2Pair) { // sell
        _burnAmount = amount.mul(_sellBurnFee).div(10000);
        _marketAmount = amount.mul(_sellMarketFee).div(10000);
       }
       if(_burnAmount > 0) {
         _basicTransfer(from, address(0xdead), _burnAmount);
       }
       if(_marketAmount > 0) {
         _basicTransfer(from, _marketAddr, _marketAmount);
       }
       amount =amount - _burnAmount - _marketAmount;
       return  amount;
    }


    function getC() public view returns (uint){
        return (block.timestamp-_startTimeForSwap)/_minPeriod;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        if(_uniswapV2Pair == address(0)) return false;
        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
    
   function getLength() public view returns(uint256 length) {
    length = _shareholders.length();
   }
    function getShareholders(uint256 start, uint256 end) public view returns (address[] memory holders) {
        holders = new address[](end - start);
        for (uint i; i < end; i ++) 
        {
            holders[i] = _shareholders.at(start +i);
        }
    }

    function process() private {
        if( getC()< lastClaimTime||theDayMint[getC()]== getMintNum()||(block.timestamp-_startTimeForSwap)<= _time ){
            return;
        }
        uint256 shareholderCount = _shareholders.length();
        
        if(shareholderCount == 0)return;
        
        uint256 tokenBal =  getMintNum();
        uint ss = everyDivi>shareholderCount?shareholderCount:everyDivi;

        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        
        for(uint i;i<ss;i++){
            if(getC()<lastClaimTime){
                break;
            }
            if(_currentIndex >= shareholderCount){
                _currentIndex = 0;
                lastClaimTime += 1;
            }
            uint256 amount = tokenBal.mul( pairAmount[_shareholders.at(_currentIndex)] ).div(getLpTotal());
            uint256 _pairAmount = mainPair.balanceOf(_shareholders.at(_currentIndex));
            if( amount < 1e13 ||_isDividendExempt[_shareholders.at(_currentIndex)]
            ||addLPTime[_shareholders.at(_currentIndex)]+(_lpTime)>block.timestamp
            ||addLPTime[_shareholders.at(_currentIndex)]==0
            ||pairAmount[_shareholders.at(_currentIndex)] > _pairAmount) {
            //The calculated value will always be smaller than the LP value. If someone transfers LP, the judgment will fail.
                _currentIndex++;
                continue;
            }

            if(theDayMint[getC()]+amount>=tokenBal){
                amount =tokenBal>theDayMint[getC()]? (tokenBal - theDayMint[getC()]):0 ;
                //Protect the program from reporting errors
            }
            _basicTransfer(address(this),_shareholders.at(_currentIndex),amount);
            theDayMint[getC()]+=amount;
            _currentIndex++;
        }
    }

    function setShare(address shareholder) private {
        if(_shareholders.contains(shareholder) ){      
            if(IERC20(_uniswapV2Pair).balanceOf(shareholder) == 0) _shareholders.remove(shareholder);            
            return;  
        }
        _shareholders.add(shareholder);
    }



    function _isAddLiquidity() internal view returns (bool isAdd){
        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }


    EnumerableSet.AddressSet _shareholders; 

    function getHolder() public view returns (address [] memory) {
        return _shareholders.values();
    }

     function getHolder(uint i) public view returns (address) {
        return _shareholders.at(i);
    }


    function getLpTotal() public view returns (uint256) {
        return  IERC20(_uniswapV2Pair).totalSupply() - IERC20(_uniswapV2Pair).balanceOf(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE)
         - IERC20(_uniswapV2Pair).balanceOf(address(0xdead));
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        _tOwned[sender] = _tOwned[sender].sub(amount, "Insufficient Balance");
        _tOwned[recipient] = _tOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }



    function getMintNum() public  view returns(uint num){
        if(_startTimeForSwap == 0||balanceOf(address(this))==0 ) return 0 ;
        if((block.timestamp - _startTimeForSwap) /_intervalSecondsForSwap==0){
            num = ddd ;
        }else{
            uint256 count = (block.timestamp - _startTimeForSwap) /_intervalSecondsForSwap;
            if(count < 5) {
              num =  ddd/( 2**count );
            }else{
                num = 12500e18;
            }

        }
    }


    function getRemoveLiquidity() internal view returns (uint256 isRemove){
        if(_uniswapV2Pair == address(0)) return isRemove=0;
         IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r - bal;
    }


    function getRemoveLP(uint amount) public view returns (uint liquidity){
        IUniswapV2Pair mainPair = IUniswapV2Pair(_uniswapV2Pair);
        uint _totalSupply = mainPair.totalSupply(); 
        if(_totalSupply == 0 ) return 0;
        (uint r0,uint256 r1,) = mainPair.getReserves();
        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r1;
        } else {
            r = r0;
        }
        liquidity= amount*_totalSupply/ (r-amount);
    }
 
   

}