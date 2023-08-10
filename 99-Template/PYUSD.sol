// SPDX-License-Identifier: MIT
// File: contracts/zeppelin/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev 包含安全检查的数学操作，溢出时会触发异常
 */
library SafeMath {
    /**
    * @dev 减法操作，溢出时会触发异常（即如果减数大于被减数）。
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev 加法操作，溢出时会触发异常。
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}


// File: contracts/PYUSDImplementation.sol

pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


contract PYUSDImplementation {

    /**
     * MATH 数学运算
     */

    using SafeMath for uint256;

    /**
     * DATA 数据
     */

    // INITIALIZATION DATA 初始化数据
    bool private initialized;

    // ERC20 BASIC DATA ERC20基本数据
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "PayPal USD"; // solium-disable-line
    string public constant symbol = "PYUSD"; // solium-disable-line uppercase
    uint8 public constant decimals = 6; // solium-disable-line uppercase

    // ERC20 DATA ERC20数据
    mapping(address => mapping(address => uint256)) internal allowed;

    // OWNER DATA PART 1 所有者数据（第一部分）
    address public owner;

    // PAUSABILITY DATA 暂停功能数据
    bool public paused;

    // ASSET PROTECTION DATA 资产保护数据
    address public assetProtectionRole;
    mapping(address => bool) internal frozen;

    // SUPPLY CONTROL DATA 供应控制数据
    address public supplyController;

    // OWNER DATA PART 2 所有者数据（第二部分）
    address public proposedOwner;

    // DELEGATED TRANSFER DATA 委托转账数据
    address public betaDelegateWhitelister;
    mapping(address => bool) internal betaDelegateWhitelist;
    mapping(address => uint256) internal nextSeqs;
    // EIP191 header for EIP712 prefix 用于EIP712前缀的EIP191标头
    string constant internal EIP191_HEADER = "\x19\x01";
    // Hash of the EIP712 Domain Separator Schema EIP712域分隔符模式的哈希
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
        "EIP712Domain(string name,address verifyingContract)"
    );
    bytes32 constant internal EIP712_DELEGATED_TRANSFER_SCHEMA_HASH = keccak256(
        "BetaDelegatedTransfer(address to,uint256 value,uint256 fee,uint256 seq,uint256 deadline)"
    );
    // Hash of the EIP712 Domain Separator data EIP712域分隔符数据的哈希
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    /**
     * EVENTS 事件
     */

    // ERC20 BASIC EVENTS ERC20基本事件
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC20 EVENTS ERC20事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // OWNABLE EVENTS 拥有者事件
    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(
        address indexed oldProposedOwner
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    // PAUSABLE EVENTS 暂停功能事件
    event Pause();
    event Unpause();

    // ASSET PROTECTION EVENTS 资产保护事件
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet (
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

    // SUPPLY CONTROL EVENTS 供应控制事件
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );

    // DELEGATED TRANSFER EVENTS 委托转账事件
    event BetaDelegatedTransfer(
        address indexed from, address indexed to, uint256 value, uint256 seq, uint256 fee
    );
    event BetaDelegateWhitelisterSet(
        address indexed oldWhitelister,
        address indexed newWhitelister
    );
    event BetaDelegateWhitelisted(address indexed newDelegate);
    event BetaDelegateUnwhitelisted(address indexed oldDelegate);

    /**
     * FUNCTIONALITY 功能
     */

    // INITIALIZATION FUNCTIONALITY 初始化功能

    /**
     * @dev 设置初始代币数量为0、所有者和supplyController。
     * 这作为代理的构造函数，但编译为实现合约的内存模型。
     */
    function initialize() public {
        require(!initialized, "MANDATORY VERIFICATION REQUIRED: 代理已经初始化，请验证所有者和supplyController地址。");
        owner = msg.sender;
        assetProtectionRole = address(0);
        totalSupply_ = 0;
        supplyController = msg.sender;
        initializeDomainSeparator();
        initialized = true;
    }

    /**
     * 构造函数在这里用于确保初始化实现合约。
     * 一个不受控制的实现合约可能会导致与之意外交互的用户产生误导性的状态。
     */
    constructor() public {
        initialize();
        pause();
    }

    /**
     * @dev 当使用upgradeAndCall升级合约以添加委托转账时调用
     */
    function initializeDomainSeparator() private {
        // 使用合约地址哈希化名称上下文
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(name)),
            bytes32(address(this))
        ));
    }

    // ERC20 BASIC FUNCTIONALITY ERC20基本功能

    /**
    * @dev 当前总的代币数量
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev 从msg.sender向指定地址转移代币
    * 注意：使用SafeMath确保_value是非负数。
    * @param _to 转移目标地址。
    * @param _value 要转移的数量。
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0), "不能转移到零地址");
        require(!frozen[_to] && !frozen[msg.sender], "地址已被冻结");
        require(_value <= balances[msg.sender], "余额不足");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

	/**
	 * @dev 获取指定地址的余额。
	 * @param _addr 要查询余额的地址。
	 * @return 一个uint256，表示该地址拥有的代币数量。
	 */
	function balanceOf(address _addr) public view returns (uint256) {
	    return balances[_addr];
	}


    // ERC20 FUNCTIONALITY ERC20功能

    /**
     * @dev 从一个地址向另一个地址转移代币
     * @param _from 要发送代币的地址
     * @param _to 要转移到的地址
     * @param _value 要转移的代币数量
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        require(_to != address(0), "不能转移到零地址");
        require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "地址已被冻结");
        require(_value <= balances[_from], "余额不足");
        require(_value <= allowed[_from][msg.sender], "授权额度不足");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 授权某地址代表msg.sender花费指定数量的代币。
     * 注意：使用此方法更改授权额度可能存在交易排序问题的风险。
     * 一个可能的解决方案是首先将spender的授权额度降为0，然后再设置所需的值：
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender 将花费资金的地址。
     * @param _value 要授权的代币数量。
     */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "地址已被冻结");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 增加一个所有者允许某代理花费的代币数量。
     *
     * 增加授权额度最好使用此函数，以避免2次调用（并等待第一笔交易被挖掘）而不是approve。
     * @param _spender 将花费资金的地址。
     * @param _addedValue 要增加的授权额度。
     */
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "地址已被冻结");
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev 减少一个所有者允许某代理花费的代币数量。
     *
     * 减少授权额度最好使用此函数，以避免2次调用（并等待第一笔交易被挖掘）而不是approve。
     * @param _spender 将花费资金的地址。
     * @param _subtractedValue 要减少的授权额度。
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "地址已被冻结");
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev 查询某所有者允许某代理花费的代币数量。
     * @param _owner 所有者地址。
     * @param _spender 代理地址。
     * @return 代币额度。
     */
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    // OWNER FUNCTIONALITY 所有者功能

    /**
     * @dev 如果调用者不是所有者，则抛出异常。
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "只有所有者可以调用");
        _;
    }

    /**
     * @dev 允许当前所有者开始将合约的控制权转移到提议的所有者
     * @param _proposedOwner 要转移所有权的地址。
     */
    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(_proposedOwner != address(0), "不能将所有权转移到零地址");
        require(msg.sender != _proposedOwner, "调用者已经是所有者");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }
    /**
     * @dev 允许当前所有者或提议的所有者取消将合约的控制权转移到提议的所有者
     */
    function disregardProposeOwner() public {
        require(msg.sender == proposedOwner || msg.sender == owner, "只有提议的所有者或所有者可以调用");
        require(proposedOwner != address(0), "只能取消之前设置的提议所有者");
        address _oldProposedOwner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(_oldProposedOwner);
    }
    /**
     * @dev 允许提议的所有者完成将合约的控制权转移到提议的所有者。
     */
    function claimOwnership() public {
        require(msg.sender == proposedOwner, "只有提议的所有者可以调用");
        address _oldOwner = owner;
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(_oldOwner, owner);
    }

    /**
     * @dev 收回合约地址上的所有PYUSD。
     * 这将把该合约持有的PYUSD代币发送给所有者。
     * 注意：这不受冻结限制影响。
     */
    function reclaimPYUSD() external onlyOwner {
        uint256 _balance = balances[this];
        balances[this] = 0;
        balances[owner] = balances[owner].add(_balance);
        emit Transfer(this, owner, _balance);
    }

    // PAUSABILITY FUNCTIONALITY 暂停功能

    /**
     * @dev 修饰符，仅在合约未暂停时使函数可调用。
     */
    modifier whenNotPaused() {
        require(!paused, "合约已暂停");
        _;
    }

    /**
     * @dev 由所有者调用以暂停，触发已停止状态
     */
    function pause() public onlyOwner {
        require(!paused, "已经暂停");
        paused = true;
        emit Pause();
    }

    /**
     * @dev 由所有者调用以解除暂停，恢复正常状态
     */
    function unpause() public onlyOwner {
        require(paused, "已经解除暂停");
        paused = false;
        emit Unpause();
    }


	// 资产保护功能

	/**
	 * @dev 设置新的资产保护角色地址。
	 * @param _newAssetProtectionRole 允许冻结/解冻地址和查封其代币的新地址。
	 */
	function setAssetProtectionRole(address _newAssetProtectionRole) public {
	    require(msg.sender == assetProtectionRole || msg.sender == owner, "只能由资产保护角色或所有者调用");
	    require(assetProtectionRole != _newAssetProtectionRole, "新地址与当前地址相同");
	    emit AssetProtectionRoleSet(assetProtectionRole, _newAssetProtectionRole);
	    assetProtectionRole = _newAssetProtectionRole;
	}

	modifier onlyAssetProtectionRole() {
	    require(msg.sender == assetProtectionRole, "只能由资产保护角色调用");
	    _;
	}

	/**
	 * @dev 冻结地址的余额，阻止转移。
	 * @param _addr 要冻结的新地址。
	 */
	function freeze(address _addr) public onlyAssetProtectionRole {
	    require(!frozen[_addr], "地址已被冻结");
	    frozen[_addr] = true;
	    emit AddressFrozen(_addr);
	}

	/**
	 * @dev 解冻地址的余额，允许转移。
	 * @param _addr 要解冻的新地址。
	 */
	function unfreeze(address _addr) public onlyAssetProtectionRole {
	    require(frozen[_addr], "地址未被冻结");
	    frozen[_addr] = false;
	    emit AddressUnfrozen(_addr);
	}

	/**
	 * @dev 清空冻结地址的余额，并销毁代币。
	 * @param _addr 要清空的新冻结地址。
	 */
	function wipeFrozenAddress(address _addr) public onlyAssetProtectionRole {
	    require(frozen[_addr], "地址未被冻结");
	    uint256 _balance = balances[_addr];
	    balances[_addr] = 0;
	    totalSupply_ = totalSupply_.sub(_balance);
	    emit FrozenAddressWiped(_addr);
	    emit SupplyDecreased(_addr, _balance);
	    emit Transfer(_addr, address(0), _balance);
	}

	/**
	* @dev 检查地址当前是否被冻结。
	* @param _addr 要检查是否被冻结的地址。
	* @return 一个表示给定地址是否被冻结的布尔值。
	*/
	function isFrozen(address _addr) public view returns (bool) {
	    return frozen[_addr];
	}

	// 供应控制功能

	/**
	 * @dev 设置新的供应控制器地址。
	 * @param _newSupplyController 允许燃烧/铸造代币以控制供应的地址。
	 */
	function setSupplyController(address _newSupplyController) public {
	    require(msg.sender == supplyController || msg.sender == owner, "只能由供应控制器或所有者调用");
	    require(_newSupplyController != address(0), "不能将供应控制器设置为零地址");
	    require(supplyController != _newSupplyController, "新地址与当前地址相同");
	    emit SupplyControllerSet(supplyController, _newSupplyController);
	    supplyController = _newSupplyController;
	}

	modifier onlySupplyController() {
	    require(msg.sender == supplyController, "只能由供应控制器调用");
	    _;
	}

	/**
	 * @dev 通过铸造指定数量的代币来增加总供应量，增加到供应控制器账户。
	 * @param _value 要添加的代币数量。
	 * @return 表示操作是否成功的布尔值。
	 */
	function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
	    totalSupply_ = totalSupply_.add(_value);
	    balances[supplyController] = balances[supplyController].add(_value);
	    emit SupplyIncreased(supplyController, _value);
	    emit Transfer(address(0), supplyController, _value);
	    return true;
	}

	/**
	 * @dev 通过从供应控制器账户销毁指定数量的代币来减少总供应量。
	 * @param _value 要减少的代币数量。
	 * @return 表示操作是否成功的布尔值。
	 */
	function decreaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
	    require(_value <= balances[supplyController], "供应不足");
	    balances[supplyController] = balances[supplyController].sub(_value);
	    totalSupply_ = totalSupply_.sub(_value);
	    emit SupplyDecreased(supplyController, _value);
	    emit Transfer(supplyController, address(0), _value);
	    return true;
	}

	// 委托转账功能

	/**
	 * @dev 返回目标地址的下一个序列号。
	 * 交易者必须在下一个交易中提交nextSeqOf(交易者)才能使其有效。
	 * 注意：序列号上下文特定于此智能合约。
	 * @param target 目标地址。
	 * @return 序列号。
	 */
	//
	function nextSeqOf(address target) public view returns (uint256) {
	    return nextSeqs[target];
	}

	/**
	 * @dev 代表发送者执行转账，由委托Transfer msg上的签名标识。
	 * 将签名字节数组拆分为r、s、v以方便操作。
	 * @param sig 委托Transfer msg的签名。
	 * @param to 要转账到的地址。
	 * @param value 要转移的数量。
	 * @param fee 由委托Transfer的执行者支付的可选ERC20费用，由发送者提供。
	 * @param seq 由发送者针对此合约特定设置的序列号，以防止重播。
	 * @param deadline 预签名交易过期的块号。
	 * @return 表示操作是否成功的布尔值。
	 */
	function betaDelegatedTransfer(
	    bytes sig, address to, uint256 value, uint256 fee, uint256 seq, uint256 deadline
	) public returns (bool) {
	    require(sig.length == 65, "签名长度应为65");
	    bytes32 r;
	    bytes32 s;
	    uint8 v;
	    assembly {
	        r := mload(add(sig, 32))
	        s := mload(add(sig, 64))
	        v := byte(0, mload(add(sig, 96)))
	    }
	    _betaDelegatedTransfer(r, s, v, to, value, fee, seq, deadline);
	    return true;
	}


	 /**
	 * @dev 代表发送者执行转账，由其在 betaDelegatedTransfer 消息上的签名标识。
	 * 注意：委托人和交易者都在费用中签名。然而，交易者无法控制燃气价格，因此无法控制交易时间。
	 * 选择 Beta 前缀以避免与 ERC865 或其他地方出现的新标准冲突。
	 * 仅内部合约使用 - 请参见 betaDelegatedTransfer 和 betaDelegatedTransferBatch。
	 * @param r delegatedTransfer 消息的 r 签名。
	 * @param s delegatedTransfer 消息的 s 签名。
	 * @param v delegatedTransfer 消息的 v 签名。
	 * @param to 要转账到的地址。
	 * @param value 要转移的金额。
	 * @param fee 由委托者支付的可选 ERC20 费用，由发送者提供给 betaDelegatedTransfer 的委托人。
	 * @param seq 由发送者在此合约中特定设置的序列号，以防重播。
	 * @param deadline 预签名交易过期的区块号。
	 * @return 一个表示操作是否成功的布尔值。
	 */
	function _betaDelegatedTransfer(
	    bytes32 r, bytes32 s, uint8 v, address to, uint256 value, uint256 fee, uint256 seq, uint256 deadline
	) internal whenNotPaused returns (bool) {
	    require(betaDelegateWhitelist[msg.sender], "Beta 功能仅接受白名单委托者");
	    require(value > 0 || fee > 0, "无法使用零代币和零费用进行转账");
	    require(block.number <= deadline, "交易已过期");
	    // 防止从 ecrecover() 中的签名篡改
	    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "签名不正确");
	    require(v == 27 || v == 28, "签名不正确");

	    // EIP712 方案：https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
	    bytes32 delegatedTransferHash = keccak256(abi.encodePacked(
	        EIP712_DELEGATED_TRANSFER_SCHEMA_HASH, bytes32(to), value, fee, seq, deadline
	    ));
	    bytes32 hash = keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_HASH, delegatedTransferHash));
	    address _from = ecrecover(hash, v, r, s);

	    require(_from != address(0), "无法从签名确定发送者地址");
	    require(to != address(0), "不能使用零地址");
	    require(!frozen[to] && !frozen[_from] && !frozen[msg.sender], "地址已冻结");
	    require(value.add(fee) <= balances[_from], "资金不足");
	    require(nextSeqs[_from] == seq, "序列号不正确");

	    nextSeqs[_from] = nextSeqs[_from].add(1);
	    balances[_from] = balances[_from].sub(value.add(fee));
	    if (fee != 0) {
	        balances[msg.sender] = balances[msg.sender].add(fee);
	        emit Transfer(_from, msg.sender, fee);
	    }
	    balances[to] = balances[to].add(value);
	    emit Transfer(_from, to, value);

	    emit BetaDelegatedTransfer(_from, to, value, seq, fee);
	    return true;
	}

	/**
	 * @dev 执行代表多个发送者执行的转账批处理，由其签名标识。
	 * 参数中缺少嵌套数组支持，要求所有参数均作为相等大小的数组传递，
	 * 其中委托传输编号 i 是索引 i 处所有参数的组合。
	 * @param r delegatedTransfer 消息的 r 签名。
	 * @param s delegatedTransfer 消息的 s 签名。
	 * @param v delegatedTransfer 消息的 v 签名。
	 * @param to 要转账到的地址。
	 * @param value 要转移的金额。
	 * @param fee 由委托者支付的可选 ERC20 费用，由发送者提供给 betaDelegatedTransfer 的委托人。
	 * @param seq 由发送者在此合约中特定设置的序列号，以防重播。
	 * @param deadline 预签名交易过期的区块号。
	 * @return 一个表示操作是否成功的布尔值。
	 */
	function betaDelegatedTransferBatch(
	    bytes32[] r, bytes32[] s, uint8[] v, address[] to, uint256[] value, uint256[] fee, uint256[] seq, uint256[] deadline
	) public returns (bool) {
	    require(r.length == s.length && r.length == v.length && r.length == to.length && r.length == value.length, "长度不匹配");
	    require(r.length == fee.length && r.length == seq.length && r.length == deadline.length, "长度不匹配");

	    for (uint i = 0; i < r.length; i++) {
	        _betaDelegatedTransfer(r[i], s[i], v[i], to[i], value[i], fee[i], seq[i], deadline[i]);
	    }
	    return true;
	}

	/**
	* @dev 获取地址是否当前为 betaDelegateTransfer 设置了白名单。
	* @param _addr 要检查是否设置了白名单的地址。
	* @return 一个表示给定地址是否设置了白名单的布尔值。
	*/
	function isWhitelistedBetaDelegate(address _addr) public view returns (bool) {
	    return betaDelegateWhitelist[_addr];
	}

	/**
	 * @dev 设置新的 betaDelegate 设置白名单的地址。
	 * @param _newWhitelister 允许设置 betaDelegate 白名单的地址。
	 */
	function setBetaDelegateWhitelister(address _newWhitelister) public {
	    require(msg.sender == betaDelegateWhitelister || msg.sender == owner, "只能由白名单设置者或所有者调用");
	    require(betaDelegateWhitelister != _newWhitelister, "新地址与当前地址相同");
	    betaDelegateWhitelister = _newWhitelister;
	    emit BetaDelegateWhitelisterSet(betaDelegateWhitelister, _newWhitelister);
	}

	modifier onlyBetaDelegateWhitelister() {
	    require(msg.sender == betaDelegateWhitelister, "只有白名单设置者可以调用");
	    _;
	}

	/**
	 * @dev 将地址添加到白名单，允许调用 BetaDelegatedTransfer。
	 * @param _addr 要添加到白名单的新地址。
	 */
	function whitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
	    require(!betaDelegateWhitelist[_addr], "地址已在白名单中");
	    betaDelegateWhitelist[_addr] = true;
	    emit BetaDelegateWhitelisted(_addr);
	}

	/**
	 * @dev 将地址从白名单中移除，不允许调用 BetaDelegatedTransfer。
	 * @param _addr 要从白名单中移除的地址。
	 */
	function unwhitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
	    require(betaDelegateWhitelist[_addr], "地址未在白名单中");
	    betaDelegateWhitelist[_addr] = false;
	    emit BetaDelegateUnwhitelisted(_addr);
	}
}
