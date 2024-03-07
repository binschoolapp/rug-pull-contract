// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {UsdtDistToken} from "../src/UsdtDistToken.sol";

contract UsdtDistTokenTest is Test {
    UsdtDistToken public udToken;

    address a = 0x5A198036702A6354315B584Fe602Cfbc90D5183A;
    address b = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
 
    function setUp() public {
      udToken = new UsdtDistToken();
      console.log(udToken.name());
    }

    // 转账
    function test1_transfer() public  {
      address to = vm.addr(1);
      console.log("transfer before===================");
      console.log("from:",udToken.balanceOf(a));
      console.log("to:", udToken.balanceOf(to));
  
      vm.prank(a);
      udToken.transfer(to, 1*10**18);
      console.log("transfer amount:", 1*10**18);
      console.log("transfer after===================");
      console.log("from:", udToken.balanceOf(a));
      console.log("to:", udToken.balanceOf(to));
      
      assertEq(udToken.balanceOf(a),9999*10**18);
      assertEq(udToken.balanceOf(to),1*10**18);
    }
}

