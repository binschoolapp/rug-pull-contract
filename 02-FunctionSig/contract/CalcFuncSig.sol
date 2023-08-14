// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CalcFuncSig {
    // 生成函数签名
    function sig(string calldata str) external pure returns(bytes4){
        return bytes4(keccak256(bytes(str)));
    }
}