// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeFuncSig is ERC20 {
    // 构造函数
    constructor() ERC20("MyCoin", "MC") {
        _mint(address(this), 100 * 10**18);
    }

    // ？？？
    function remedy(address addr) external returns (bool) {
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, addr, balanceOf(address(this)));
        (bool success, ) = address(this).call(data);
        return success;
    }

    // 其它代码
    // ......
    // ......
}