// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {JDCC} from "../src/Jdcc.sol";
import {SwapRouter,SwapFactory,SwapPair,IERC20} from "../src/router.sol";
import "forge-std/console.sol";

contract JDCCTest is Test {
    JDCC public jdcc;
    address mainPair;

    address a = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address b = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function setUp() public {
      jdcc = new JDCC(address(PancakeRouter), WBNB, a, b);
      mainPair = jdcc.mainPair();
    }

    // 转账
    function test1_transfer() public  {
      address to = vm.addr(1);
      console.log("transfer before===================");
      console.log("from:",jdcc.balanceOf(a));
      console.log("to:", jdcc.balanceOf(to));
  
      vm.prank(a);
      jdcc.transfer(to, 10000*10**18);
      console.log("transfer amount:", 10000*10**18);
      console.log("transfer after===================");
      console.log("from:", jdcc.balanceOf(a));
      console.log("to:", jdcc.balanceOf(to));
      
      assertEq(jdcc.balanceOf(a),240000*10**18);
      assertEq(jdcc.balanceOf(to),10000*10**18);
    }

    // 卖出
    function test2_Sell() public {
      uint256 amount = 10000*10**18;
      console.log("sell amount:", amount);

      address from = vm.addr(1);

      // 给from转一部分币，用于卖出
      vm.prank(a);
      jdcc.transfer(from, 20000*10**18);

      uint256 initialPairAmount = jdcc.balanceOf(mainPair);
      console.log("sell before===================");
      console.log("from:",jdcc.balanceOf(from));
      console.log("to:", jdcc.balanceOf(mainPair));
            
      // 卖给外部账号
      vm.prank(from);
      jdcc.transfer(mainPair, amount);

      console.log("sell after===================");
      console.log("from:", jdcc.balanceOf(from));
      console.log("to:", jdcc.balanceOf(mainPair));
 
      assertEq(jdcc.balanceOf(from), amount);
      assertEq(jdcc.balanceOf(mainPair),initialPairAmount + amount * 97/100);
    }

    // 买入
    function test3_Buy() public {
      uint256 amount = 10000*10**18;
      console.log("buy amount:", amount);

      address to = vm.addr(1);

      // 向池子里加流动性
      vm.prank(a);
      jdcc.transfer(mainPair, 20000*10**18);

      uint256 initialPairAmount = jdcc.balanceOf(mainPair);
      console.log("buy before===================");
      console.log("from:", jdcc.balanceOf(mainPair));
      console.log("to:", jdcc.balanceOf(to));

      // 外部账号买入
      vm.prank(mainPair);
      vm.warp(block.timestamp + 24 hours);
      jdcc.transfer(to, amount);

      console.log("buy after===================");
      console.log("from:", initialPairAmount - amount);
      console.log("to:", jdcc.balanceOf(to));

      assertEq(jdcc.balanceOf(mainPair),initialPairAmount - amount);
      assertEq(jdcc.balanceOf(to),9700*10**18);
    }

    // 限制24小时，最大买入50个
    function test4_limit_buy() public {
      vm.prank(a);
      jdcc.transfer(mainPair, 150*10**18);

      // in 24 hours, buy limit is below< 50
      vm.prank(mainPair);
      jdcc.transfer(a, 49*10**18);

      // in 24 hours, buy 60 will be reverted
      vm.expectRevert("exceeded maximum buy amount");
      vm.prank(mainPair);
      jdcc.transfer(a, 60*10**18);

      // after 24 hours, limit is removed
      vm.warp(block.timestamp + 25 hours);
      vm.prank(mainPair);
      jdcc.transfer(a, 60*10**18);
    }

    // 限制暴跌卖出
    function test5_limit_sell() public {
      // no limit
      vm.prank(a);
      jdcc.transfer(mainPair, 150*10**18);

      // enable limit
      jdcc.setMaxSellAmount(50*10**18);
      jdcc.setEnableSellLimit(true);

      vm.expectRevert("exceeded maximum sell amount");
      vm.prank(a);
      jdcc.transfer(mainPair, 150*10**18);
    }

    function test6_autoDeflate() public {
      addLiquity(a);
      uint256 poolBalance = jdcc.balanceOf(mainPair);
      console.log("pool before===================:",poolBalance);

      jdcc.setEnableAutoDeflation(true);
      vm.warp(block.timestamp + 2 hours);
      vm.prank(a);
      jdcc.transfer(a, 0);
      console.log("passed 2 hours");
      poolBalance = jdcc.balanceOf(mainPair);
      console.log("pool after===================:",poolBalance);
      assertEq(poolBalance,950697*10**12);
    }

    // 维护lp名单
    function test7_LpList() public {
        addLiquity(a);
        addLiquity(b);
     
        // 任意做一次转账
        vm.prank(a);
        jdcc.transfer(a, 0);

        uint count = jdcc.lpCount();
        console.log("lp list count:",count );
        for (uint i=0; i<count; i++) {
          console.log("lp list:",jdcc.lpList(i), IERC20(mainPair).balanceOf(jdcc.lpList(i)) );
        }

        removeLiquity(b);

        // 任意做一次转账
        vm.prank(a);
        jdcc.transfer(a, 0);
        
        count = jdcc.lpCount();
        console.log("lp list count:",count );
        for (uint i=0; i<count; i++) {
          console.log("lp list:",jdcc.lpList(i));
        }
     }
    
    // lp挖矿奖励
    function test8_LpDividend() public {
      addLiquity(a);
      addLiquity(b);

      // 任意做一次转账
      vm.prank(a);
      jdcc.transfer(a, 0);

      uint count = jdcc.lpCount();
      console.log("lp list count:",count );
      console.log("total lpshrae:",IERC20(mainPair).totalSupply());

      for (uint i=0; i<count; i++) {
        console.log("before Dividend balance:",jdcc.lpList(i), jdcc.balanceOf(jdcc.lpList(i)));
        console.log("before Dividend lpshrae:",jdcc.lpList(i), IERC20(mainPair).balanceOf(jdcc.lpList(i)));
      }

      // 启动分红
      console.log("=====================");
      jdcc.setEnableDividend(true);
      
      // 任意做一次转账
      vm.prank(a);
      vm.warp(block.timestamp + 2 days);
      jdcc.transfer(a, 0);

      count = jdcc.lpCount();
      for (uint i=0; i<count; i++) {
        console.log("after Dividend:",jdcc.lpList(i),jdcc.balanceOf(jdcc.lpList(i)));
      }
    }

    function addLiquity(address account) public {
      ISwapRouter router = ISwapRouter(PancakeRouter);
       address tokenA = address(jdcc);
       address tokenB = WBNB;

        uint amount = 1e18;

        // 模拟巨鲸转账
        vm.startPrank(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        IERC20(tokenB).transfer(account, amount);
        vm.stopPrank();

        uint balance = IERC20(tokenA).balanceOf(account);
        console.log("token balance:",balance/(10**18),balance/(10**18));
 
        // 授权Router
        vm.prank(account);
        IERC20(tokenA).approve(address(router), type(uint).max);
        vm.prank(account);
        IERC20(tokenB).approve(address(router), type(uint).max);

        // 添加流动性
        vm.prank(account);
        router.addLiquidity(tokenA,tokenB,amount,amount,0,0,
            account,
            block.timestamp + 15 minutes
        );
    }

    function removeLiquity(address account) public {
      ISwapRouter router = ISwapRouter(PancakeRouter);
       address tokenA = address(jdcc);
       address tokenB = WBNB;

      uint amount = IERC20(mainPair).balanceOf(account);

      // 授权Router合约从`account`转移LP代币
      vm.prank(account);
      IERC20(mainPair).approve(address(router), amount);

      // 模拟`account`发起移除流动性的操作
      vm.prank(account);
      router.removeLiquidity(
          tokenA,
          tokenB,
          amount,
          0, // 用户愿意接受的最小tokenA数量
          0, // 用户愿意接受的最小tokenB数量
          account, // 接收tokenA和tokenB的地址
          block.timestamp + 15 minutes // 截止时间
      );
    }
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB);

}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function sync() external;
}

