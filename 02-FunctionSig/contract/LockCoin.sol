// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LockCoin is ERC20 {
    uint256 lockTime = block.timestamp + 365 days; // 锁定期为1年
    address owner;  // 合约创建者

    // 校验合约创建者持币是否到期
    modifier lock() {
    	// 对合约创建者的操作进行校验
        if (msg.sender == owner) {
        	// 锁定期满1年，才允许后续操作，否则回滚交易
            require(block.timestamp > lockTime, "It's still in the lockup period");
        }
        _;
    }

    // 发布代码为 MC 的代币，发行总量为 100
    constructor() ERC20("MyCoin", "MC") {
        owner = msg.sender; // 保存合约创建者
        _mint(msg.sender, 100*10**18);
    }

    // 转账操作需要符合锁定期校验
    function transfer(address to, uint256 amount) public virtual override lock returns (bool) {
        return super.transfer(to, amount);
    }
}