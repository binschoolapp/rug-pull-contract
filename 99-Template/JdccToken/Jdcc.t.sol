// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {JDCC} from "../src/Jdcc.sol";
import "forge-std/console.sol";

// ERC20接口标准
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

contract JDCCTest is Test {
    JDCC public jdcc;
    address mainPair;

    address deployer = 0xE89B09CA065aa2fC8D58F15C7A71fbdee8291bdC;
    address a = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address b = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address USDT = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;//0x55d398326f99059fF775485246999027B3197955;
    // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;


    function setUp() public {
      vm.prank(deployer);
      jdcc = new JDCC();
      mainPair = jdcc.mainPair();
    }

  function test_1() public {
            console.log("test addess:",address(this));
console.log("addess:",deployer);
      vm.prank(deployer);
      jdcc.transfer(a, 20000*10**18);

      vm.prank(deployer);
      jdcc.setFeeWhiteList(a, true);
      addLiquity(a, 100e18); // 100u, 10000jdcc
         addLiquity(a, 10e18); // 10u, 1000jdcc
  }

    // // 转账
    // function test0_balance() public  {
    //   console.log(jdcc.balanceOf(owner));
    //   console.log(jdcc.balanceOf(address(jdcc)));
      
    //   assertEq(jdcc.balanceOf(owner),298000*10**18);
    //   assertEq(jdcc.balanceOf(address(jdcc)),12000*10**18);
    // }

    // // 转账
    // function test1_transfer() public  {
    //   address to = vm.addr(1);
    //   console.log("Owner:transfer before===================");
    //   console.log("from:",jdcc.balanceOf(owner));
    //   console.log("to:", jdcc.balanceOf(to));
  
    //   vm.prank(owner);
    //   jdcc.transfer(to, 10000*10**18);
    //   console.log("transfer after===================");
    //   console.log("from:", jdcc.balanceOf(owner));
    //   console.log("to:", jdcc.balanceOf(to));
      
    //   assertEq(jdcc.balanceOf(owner),288000*10**18);
    //   assertEq(jdcc.balanceOf(to),10000*10**18);

    //   console.log("jdcc: transfer before===================");
    //   console.log("from:",jdcc.balanceOf(address(jdcc)));
    //   console.log("to:", jdcc.balanceOf(to));
    //   vm.prank(address(jdcc));
    //   jdcc.transfer(to, 10000*10**18);
    //   console.log("transfer after===================");
    //   console.log("from:", jdcc.balanceOf((address(jdcc))));
    //   console.log("to:", jdcc.balanceOf(to));
      
    //   assertEq(jdcc.balanceOf(address(jdcc)),2000*10**18);
    //   assertEq(jdcc.balanceOf(to),20000*10**18);
    // }

    //// 卖出
    // function test2_Sell() public {
    //   uint256 amount = 10000*10**18;

    //   // 给from转一部分币，用于卖出
    //   address from = vm.addr(1);
    //   vm.prank(owner);
    //   jdcc.transfer(from, amount);

    //   console.log("sell before===================");
    //   console.log("from:",jdcc.balanceOf(from));
    //   console.log("to:", jdcc.balanceOf(mainPair));
    //   assertEq(jdcc.balanceOf(from), amount);
    //   assertEq(jdcc.balanceOf(mainPair),0);

    //   // 卖给外部账号
    //   console.log("sell amount:", amount);
    //   vm.prank(from);
    //   jdcc.transfer(mainPair, amount);

    //   console.log("sell after===================");
    //   console.log("from:", jdcc.balanceOf(from));
    //   console.log("to:", jdcc.balanceOf(mainPair));
 
    //   assertEq(jdcc.balanceOf(from), 0);
    //   assertEq(jdcc.balanceOf(mainPair), amount*96/100);

    //   // 烧毁后的总量
    //   assertEq(jdcc.totalSupply(), 310000*10**18 - amount*150/10000);
    //   // 营销钱包余额
    //   assertEq(jdcc.balanceOf(0xCCC2d4D475276D0EF57E41bBC4BB6c6c39Ef91a0), amount* 150/10000);
    //   // 底池余额
    //   assertEq(jdcc.balanceOf(jdcc._poolReservoir()), amount*50/10000);
    //   // lp分红余额
    //   assertEq(jdcc.balanceOf(address(jdcc)), 12000*10**18 + amount*50/10000);
    // }

    // // 买入
    // function test3_Buy() public {
    //   uint256 amount = 10000*10**18;
    //   console.log("buy amount:", amount);

    //   address to = vm.addr(1);

    //   // 向池子里加流动性
    //   vm.prank(owner);
    //   jdcc.transfer(mainPair, 20000*10**18);

    //   uint256 initialPairAmount = jdcc.balanceOf(mainPair);
    //   console.log("buy before===================");
    //   console.log("from:", jdcc.balanceOf(mainPair));
    //   console.log("to:", jdcc.balanceOf(to));


    //   // 外部账号买入
    //   vm.prank(mainPair);
    //   vm.warp(block.timestamp + 24 hours);
    //   jdcc.transfer(to, amount);

    //   console.log("buy after===================");
    //   console.log("from:", initialPairAmount - amount);
    //   console.log("to:", jdcc.balanceOf(to));

    //   assertEq(jdcc.balanceOf(mainPair),initialPairAmount - amount);
    //   assertEq(jdcc.balanceOf(to),9600*10**18);
    // }

    // // 限制24小时，最大买入50个
    // function test4_limit_buy() public {
    //   vm.prank(owner);
    //   jdcc.transfer(mainPair, 150*10**18);

    //   // in 24 hours, buy limit is below< 50
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 49*10**18);

    //   // in 24 hours, buy 60 will be reverted
    //   vm.expectRevert("exceeded maximum buy amount");
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 60*10**18);

    //   // after 24 hours, limit is removed
    //   vm.warp(block.timestamp + 25 hours);
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 60*10**18);
    // }

    // // 限制暴跌卖出
    // function test5_limit_sell() public {
    //   // no limit
    //   vm.prank(owner);
    //   jdcc.transfer(mainPair, 150*10**18);

    //   // enable limit
    //   vm.prank(owner);
    //   jdcc.setMaxSellAmount(50*10**18);
    //   vm.prank(owner);
    //   jdcc.setEnableSellLimit(true);

    //   vm.expectRevert("exceeded maximum sell amount");
    //   vm.prank(owner);
    //   jdcc.transfer(mainPair, 150*10**18);
    // }

    // function test6_autoDeflate1() public {
    //   vm.prank(deployer);
    //   jdcc.transfer(a, 20000*10**18);

    //   vm.prank(deployer);
    //   jdcc.setFeeWhiteList(a, true);
    //   addLiquity(a, 100e18); // 100u, 10000jdcc

    //   vm.warp(block.timestamp + 1 hours);
    //   vm.prank(a);
    //   jdcc.transfer(a, 0);
   
    //   console.log("passed 1 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("pool after jdcc===================:",poolBalance);
    //   assertEq(poolBalance,9925e18); // 100u, 10000*0.9925=9925jdcc
    // }

    // function test6_autoDeflate2() public {
    //   // 模拟交易两次，收取手续费到底池
    //   vm.prank(deployer);
    //   jdcc.transfer(a, 20000*10**18);

    //   vm.prank(a);
    //   jdcc.transfer(mainPair, 10000*10**18);//共收取了98个
      
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 9600*10**18);
    //   console.log("=========_poolReservoir==========:",jdcc._poolReservoir(),jdcc.balanceOf(jdcc._poolReservoir()));
    //   assertEq(jdcc.balanceOf(jdcc._poolReservoir()),98e18); // 两次交易费0.5%

    //   vm.prank(deployer);
    //   jdcc.setFeeWhiteList(a, true);
    //   addLiquity(a, 100e18); // 100u, 10000jdcc
    //   console.log("before:mainPair jdcc==========:",jdcc.balanceOf(mainPair));
    //   console.log("before:poolReservoir jdcc==========:",jdcc.balanceOf(jdcc._poolReservoir()));

    //   vm.warp(block.timestamp + 1 hours);
    //   vm.prank(a);
    //   jdcc.transfer(a, 0);
   
    //   console.log("passed 1 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("after:mainPair jdcc===================:",poolBalance);
    //   console.log("after:poolReservoir jdcc==========:",jdcc.balanceOf(jdcc._poolReservoir()));
    //   assertEq(poolBalance,10022265e15); // 100u, 10098*0.9925=10022.265jdcc
    //   assertEq(jdcc.balanceOf(jdcc._poolReservoir()),0); // 转到了底池
    // }

    // function test6_autoDeflate3() public {
    //   ISwapRouter router = ISwapRouter(PancakeRouter);
    //   address w = router.WETH();
    //   console.log(w);

    //   vm.prank(deployer);
    //   jdcc.transfer(a, 20000*10**18);

    //   vm.prank(deployer);
    //   jdcc.setFeeWhiteList(a, true);
    //   addLiquity(a, 60e18); // 100u, 6000jdcc

    //   vm.warp(block.timestamp + 10 hours);
    //   vm.prank(a);
    //   jdcc.transfer(a, 0);

    //   console.log("passed 10 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("pool after jdcc===================:",poolBalance);
    //   assertEq(poolBalance,5513e18); // 100u, 底池5513jdcc
    // }

    // // 维护lp名单
    // function test7_LpList() public {
    //     addLiquity(a);
    //     addLiquity(b);
     
    //     // 任意做一次转账
    //     vm.prank(a);
    //     jdcc.transfer(a, 0);

    //     uint count = jdcc.lpCount();
    //     console.log("lp list count:",count );
    //     for (uint i=0; i<count; i++) {
    //       console.log("lp list:",jdcc.lpList(i), IERC20(mainPair).balanceOf(jdcc.lpList(i)) );
    //     }

    //     removeLiquity(b);

    //     // 任意做一次转账
    //     vm.prank(a);
    //     jdcc.transfer(a, 0);
        
    //     count = jdcc.lpCount();
    //     console.log("lp list count:",count );
    //     for (uint i=0; i<count; i++) {
    //       console.log("lp list:",jdcc.lpList(i));
    //     }
    //  }
    
    // // lp挖矿奖励
    // function test8_LpDividend() public {
    //   addLiquity(a);
    //   addLiquity(b);

    //   // 任意做一次转账
    //   vm.prank(a);
    //   jdcc.transfer(a, 0);

    //   uint count = jdcc.lpCount();
    //   console.log("lp list count:",count );
    //   console.log("total lpshrae:",IERC20(mainPair).totalSupply());

    //   for (uint i=0; i<count; i++) {
    //     console.log("before Dividend balance:",jdcc.lpList(i), jdcc.balanceOf(jdcc.lpList(i)));
    //     console.log("before Dividend lpshrae:",jdcc.lpList(i), IERC20(mainPair).balanceOf(jdcc.lpList(i)));
    //   }

    //   // 启动分红
    //   console.log("=====================");
      
    //   // 任意做一次转账
    //   vm.prank(a);
    //   vm.warp(block.timestamp + 2 days);
    //   jdcc.transfer(a, 0);

    //   count = jdcc.lpCount();
    //   for (uint i=0; i<count; i++) {
    //     console.log("after Dividend:",jdcc.lpList(i),jdcc.balanceOf(jdcc.lpList(i)));
    //   }
    // }

    function addLiquity(address account, uint256 amount) public {
       ISwapRouter router = ISwapRouter(PancakeRouter);
       address tokenA = address(jdcc);
       address tokenB = USDT;

        // 模拟巨鲸转账
        vm.startPrank(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        IERC20(tokenB).transfer(account, amount);
        vm.stopPrank();

        // uint balance = IERC20(tokenA).balanceOf(account);
        // console.log("token balance:",balance/(10**18));
 
        // 授权Router
        vm.prank(account);
        IERC20(tokenA).approve(address(router), type(uint).max);
        vm.prank(account);
        IERC20(tokenB).approve(address(router), type(uint).max);

        // 添加流动性
        vm.prank(account);
        console.log("account:", account);
        router.addLiquidity(tokenA,tokenB,amount*100,amount,0,0,
            account,
            block.timestamp + 15 minutes
        );

        console.log("lp jdcc balance:",IERC20(tokenA).balanceOf(mainPair)/(10**18));
        console.log("lp usdt balance:",IERC20(tokenB).balanceOf(mainPair)/(10**18));
    }

    function removeLiquity(address account) public {
      ISwapRouter router = ISwapRouter(PancakeRouter);
       address tokenA = address(jdcc);
       address tokenB = USDT;

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
    function WETH() external pure returns (address);
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


