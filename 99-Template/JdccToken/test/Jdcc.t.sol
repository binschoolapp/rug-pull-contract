// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {JDCC} from "../src/JDCC.sol";
import {Distributor} from "../src/Distributor.sol";
import "forge-std/console.sol";

// ERC20接口标准
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address deployer, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed deployer, address indexed spender, uint256 value);
}

contract JDCCTest is Test {
    JDCC public jdcc;
    Distributor public distributor;

    address mainPair;

    address deployer = 0xE89B09CA065aa2fC8D58F15C7A71fbdee8291bdC;
    address a = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address b = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address PancakeRouter = block.chainid == 56? 
            0x10ED43C718714eb63d5aA57B78B54704E256024E : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; 

    // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    //0x55d398326f99059fF775485246999027B3197955;
    // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;


    function setUp() public {
      vm.startPrank(deployer);
      jdcc = new JDCC();
      mainPair = jdcc.mainPair();

      distributor = new Distributor();
      jdcc.setFundAddess(address(distributor));
      jdcc.setFundReservoirAddress(distributor.reservoir());
      jdcc.setInsureAddress(0x67C6f207AD1D34C668D71eC47Eb99d889129CDc1);

      distributor.setJDCC(address(jdcc));
      vm.stopPrank();
    }

    // // 余额
    // function test0_balance() public  {
    //   console.log(jdcc.balanceOf(deployer));
    //   console.log(jdcc.balanceOf(address(jdcc)));
      
    //   assertEq(jdcc.balanceOf(deployer),298000 ether);
    //   assertEq(jdcc.balanceOf(address(jdcc)),12000 ether);
    // }

    // // 转账
    // function test1_transfer() public  {
    //   address to = vm.addr(1);
    //   console.log("deployer:transfer before===================");
    //   console.log("from:",jdcc.balanceOf(deployer)/10**18);
    //   console.log("to:", jdcc.balanceOf(to)/10**18);
  
    //   vm.prank(deployer);
    //   jdcc.transfer(to, 10000 ether);
    //   console.log("transfer after===================");
    //   console.log("from:", jdcc.balanceOf(deployer)/10**18);
    //   console.log("to:", jdcc.balanceOf(to)/10**18);
      
    //   assertEq(jdcc.balanceOf(deployer),288000 ether);
    //   assertEq(jdcc.balanceOf(to),10000 ether);

    //   console.log("jdcc: transfer before===================");
    //   console.log("from:",jdcc.balanceOf(address(jdcc))/10**18);
    //   console.log("to:", jdcc.balanceOf(to)/10**18);
    //   vm.prank(address(jdcc));
    //   jdcc.transfer(to, 10000 ether);
    //   console.log("transfer after===================");
    //   console.log("from:", jdcc.balanceOf((address(jdcc)))/10**18);
    //   console.log("to:", jdcc.balanceOf(to)/10**18);
      
    //   assertEq(jdcc.balanceOf(address(jdcc)),2000 ether);
    //   assertEq(jdcc.balanceOf(to),20000 ether);
    // }

    // 卖出
    function test2_Sell1() public {
      uint256 amount = 10000 ether;

      // 2小时内 收税30%
      // 给from转一部分币，用于卖出
      address from = vm.addr(1);
      vm.prank(deployer);
      jdcc.transfer(from, amount);

      // console.log("===================");
      // console.log("sell before from-to:", jdcc.balanceOf(from)/10**18, jdcc.balanceOf(mainPair)/10**18);
      // assertEq(jdcc.balanceOf(from)/10**18, amount/10**18);
      // assertEq(jdcc.balanceOf(mainPair)/10**18,0);

      // 卖给外部账号
      vm.prank(from);
      jdcc.transfer(mainPair, amount);

      console.log("===================");
      console.log("sell after from-to:", jdcc.balanceOf(from)/10**18, jdcc.balanceOf(mainPair)/10**18);
 
      assertEq(jdcc.balanceOf(from)/10**18, 0);
      assertEq(jdcc.balanceOf(mainPair)/10**18, 7000);

      // 烧毁后的总量
      assertEq(jdcc.totalSupply(), 310000 ether - amount*150/10000);
      // 营销钱包余额
      assertEq(jdcc.balanceOf(jdcc.fundAddress()), amount* 2700/10000);
      // 底池余额
      assertEq(jdcc.balanceOf(jdcc.poolReservoir()), amount*50/10000);
      // lp分红余额
      assertEq(jdcc.balanceOf(address(jdcc)), 12000 ether + amount*50/10000);
      // 保护基金
      assertEq(jdcc.balanceOf(jdcc.insureAddress()), amount* 50/10000);

      // 2小时后，收税4%
      from = vm.addr(2);
      vm.warp(block.timestamp + 2 hours);
      vm.prank(deployer);
      jdcc.transfer(from, amount);

      // 卖给外部账号
      vm.prank(from);
      jdcc.transfer(mainPair, amount);
      assertEq(jdcc.balanceOf(mainPair)/10**18, 6944/*7000 2小时自动收缩*/ + 9600);
    }

    // // 买入
    // function test3_Buy() public {
    //   uint256 amount = 10000 ether;
    //   console.log("buy amount:", amount);

    //   address to = vm.addr(1);

    //   // 向池子里加流动性
    //   vm.prank(deployer);
    //   jdcc.transfer(mainPair, 10000 ether);

    //   uint256 initialPairAmount = jdcc.balanceOf(mainPair);
    //   console.log("from-to:", jdcc.balanceOf(mainPair)/10**18, jdcc.balanceOf(to)/10**18);

    //   // 外部账号买入
    //   vm.prank(mainPair);
    //   vm.warp(block.timestamp);
    //   jdcc.transfer(to, amount);

    //   console.log("buy after===================");
    //   console.log("from-to:", jdcc.balanceOf(mainPair)/10**18, jdcc.balanceOf(to)/10**18);

    //   assertEq(jdcc.balanceOf(mainPair),initialPairAmount - amount);
    //   assertEq(jdcc.balanceOf(to),9600 ether);

    //   // 烧毁后的总量
    //   assertEq(jdcc.totalSupply(), 310000 ether - amount*150/10000);
    //   // 营销钱包余额
    //   assertEq(jdcc.balanceOf(jdcc.fundAddress()), amount* 100/10000);
    //   // 底池余额
    //   assertEq(jdcc.balanceOf(jdcc.poolReservoir()), amount*50/10000);
    //   // lp分红余额
    //   assertEq(jdcc.balanceOf(address(jdcc)), 12000 ether + amount*50/10000);
    //   // 保护基金
    //   assertEq(jdcc.balanceOf(jdcc.protectionAddress()), amount* 50/10000);
    //   console.log("protectionAddress:",jdcc.balanceOf(jdcc.protectionAddress())/10**18 );
    // }

    // // 限制24小时，最大买入50个
    // function test4_limit_buy() public {
    //   vm.prank(deployer);
    //   jdcc.transfer(mainPair, 1000 ether);

    //   // in 24 hours, buy limit is below<= 200
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 200 ether);

    //   // in 24 hours, buy 201 will be reverted
    //   vm.expectRevert("exceeded maximum buy amount");
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 201 ether);

    //   // after 24 hours, limit is removed
    //   vm.warp(block.timestamp + 25 hours);
    //   vm.prank(mainPair);
    //   jdcc.transfer(a, 201 ether);
    // }

    // // 限制暴跌卖出
    // function test5_limit_sell() public {
    //   vm.startPrank(deployer);
    //   // no limit
    //   jdcc.transfer(mainPair, 150 ether);

    //   // enable limit
    //   jdcc.setMaxSellAmount(50 ether);
    //   jdcc.setEnableSellLimit(true);

    //   vm.expectRevert("exceeded maximum sell amount");
    //   jdcc.transfer(mainPair, 150 ether);
    //   vm.stopPrank();
    // }

    // function test6_autoDeflate1() public {
    //   address testAccount = vm.addr(1);

    //   vm.startPrank(deployer);
    //   jdcc.transfer(testAccount, 20000 ether);
    //   jdcc.setFeeWhiteList(testAccount, true);
    //   vm.stopPrank();

    //   addLiquity(testAccount, 100e18); // 100u, 10000jdcc

    //   vm.warp(block.timestamp + 1 hours);
    //   vm.prank(testAccount);
    //   jdcc.transfer(b, 0);

    //   console.log("passed 1 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("pool after jdcc===================:",poolBalance);
    //   assertEq(poolBalance/10**18,9925); // 100u, 10000*0.9925=9925jdcc
    // }

    // function test6_autoDeflate2() public {
    //   address testAccount = vm.addr(1);

    //   vm.startPrank(deployer);
    //   jdcc.transfer(testAccount, 20000 ether);
    //   jdcc.transfer(jdcc.poolReservoir(), 5000 ether);
    //   jdcc.setFeeWhiteList(testAccount, true);
    //   vm.stopPrank();

    //   addLiquity(testAccount, 50e18); // 100u, 10000jdcc

    //   vm.warp(block.timestamp + 1 hours);
    //   vm.prank(testAccount);
    //   jdcc.transfer(b, 0);

    //   console.log("passed 1 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("pool after jdcc===================:",poolBalance);
    //   assertEq(poolBalance/10**18,9925); // 50u, 10000*0.9925=9925jdcc
    // }

    // function test6_autoDeflate3() public {
    //   address testAccount = vm.addr(1);

    //   vm.startPrank(deployer);
    //   jdcc.transfer(testAccount, 20000 ether);
    //   jdcc.setFeeWhiteList(testAccount, true);
    //   vm.stopPrank();

    //   addLiquity(testAccount, 58e18); // 100u, 10000jdcc

    //   vm.warp(block.timestamp + 8 hours);
    //   vm.prank(testAccount);
    //   jdcc.transfer(b, 0);

    //   console.log("passed 8 hours");
    //   uint256 poolBalance = jdcc.balanceOf(mainPair);
    //   console.log("pool after jdcc===================:",poolBalance/10**18);
    //   assertEq(poolBalance,5513e18); // 58u, 5800 min=5513jddc
    // }

    
    // // lp挖矿奖励
    // function test8_LpDividend() public {
    //   address testAccount = vm.addr(1);
    // address testAccount1 = vm.addr(2);
    //   vm.startPrank(deployer);
    //   jdcc.transfer(testAccount, 20000 ether);
    //   jdcc.setFeeWhiteList(testAccount, true);
    //  jdcc.transfer(testAccount1, 20000 ether);
    //   jdcc.setFeeWhiteList(testAccount1, true);
    //   vm.stopPrank();

    //   addLiquity(testAccount, 100e18); // 100u, 10000jdcc
    //   addLiquity(testAccount1, 100e18);// 100u, 10000jdcc
    //   // 任意做一次转账
    //   vm.startPrank(deployer);
      
    //   address[] memory accounts = new address[](2);
    //   accounts[0]=testAccount;
    //   accounts[1]=testAccount1;
    //   jdcc.setInitLP(accounts);
    //   jdcc.transfer(deployer, 0);
 
    //   uint count = jdcc.lpCount();
    //   console.log("lp list count:",count );
    //   console.log("total lpshrae:",IERC20(mainPair).totalSupply());
  
    //   for (uint i=0; i<count; i++) {
    //     address account = jdcc.lpList(i);
    //     console.log("before Dividend balance:",account, jdcc.balanceOf(account));
    //     console.log("before Dividend lpshrae:",account, IERC20(mainPair).balanceOf(account));
    //   }

  
    //   // 启动分红
    //   console.log("=====================");
      
    //   // 任意做一次转账
    //   vm.warp(block.timestamp + 1 days);
    //   jdcc.transfer(deployer, 0);

    //   count = jdcc.lpCount();
    //   for (uint i=0; i<count; i++) {
    //     address account = jdcc.lpList(i);
    //     console.log("after Dividend:",account,jdcc.balanceOf(account));
    //   }

    //   vm.stopPrank();
    // }

// // lp挖矿奖励
//     function test8_LpDividend() public {
//       addLiquity(a);
//       addLiquity(b);

//       // 任意做一次转账
//       vm.prank(a);
//       jdcc.transfer(a, 0);

//       uint count = jdcc.lpCount();
//       console.log("lp list count:",count );
//       console.log("total lpshrae:",IERC20(mainPair).totalSupply());

//       for (uint i=0; i<count; i++) {
//         console.log("before Dividend balance:",jdcc.lpList(i), jdcc.balanceOf(jdcc.lpList(i)));
//         console.log("before Dividend lpshrae:",jdcc.lpList(i), IERC20(mainPair).balanceOf(jdcc.lpList(i)));
//       }

//       // 启动分红
//       console.log("=====================");
      
//       // 任意做一次转账
//       vm.prank(a);
//       vm.warp(block.timestamp + 2 days);
//       jdcc.transfer(a, 0);

//       count = jdcc.lpCount();
//       for (uint i=0; i<count; i++) {
//         console.log("after Dividend:",jdcc.lpList(i),jdcc.balanceOf(jdcc.lpList(i)));
//       }
//     }

  //   // 黑名单
  //   function test9_blacklist() public {
  //     address account = vm.addr(1);
  //     vm.startPrank(deployer);
  //     jdcc.transfer(account, 1000 ether);
  //     assertEq(jdcc.balanceOf(account)/10**18,1000); 

  //     // added to blacklist
  //     jdcc.setBlacklist(account, true);
  //     vm.expectRevert("the address is in the blacklist");
  //     jdcc.transfer(account, 1000 ether);

  //     // removed from blacklist
  //     jdcc.setBlacklist(account, false);
  //     jdcc.transfer(account, 1000 ether);
  //     assertEq(jdcc.balanceOf(account)/10**18,2000); 

  //     // after renounce Ownership
  //     jdcc.setBlacklist(account, true); // added to blacklist
  //     jdcc.renounceOwnership();
  //     jdcc.transfer(account, 1000 ether);
  //     assertEq(jdcc.balanceOf(account)/10**18,3000); 
  //     vm.stopPrank();
  //   }

  //  // 征收附加税
  //   function test10_extraFee() public {
  //     address account = vm.addr(1);
  //     vm.startPrank(deployer);
  //     jdcc.transfer(account, 100 ether);
  //     vm.stopPrank();
      
  //     vm.startPrank(account);
  //     jdcc.transfer(mainPair, 100 ether);
  //     vm.stopPrank();
  //     console.log("mainPair balance:", jdcc.balanceOf(mainPair)/10**18);
  //     assertEq(jdcc.balanceOf(mainPair)/10**18,70); // got 70%

  //     vm.startPrank(mainPair);
  //     jdcc.transfer(account, 70 ether);
  //     vm.stopPrank();
  //     assertEq(jdcc.balanceOf(account)/10**17,672); // got 96%

  //     vm.warp(block.timestamp + 2 hours);
  //     account = vm.addr(2);
  //     vm.startPrank(deployer);
  //     jdcc.transfer(account, 100 ether);
  //     vm.stopPrank();

  //     vm.startPrank(account);
  //     jdcc.transfer(mainPair, 100 ether);
  //     vm.stopPrank();
  //     console.log("mainPair balance:", jdcc.balanceOf(mainPair)/10**18);
  //     assertEq(jdcc.balanceOf(mainPair)/10**18,96); // got 96%
  //   }

    // // after auto Deflation，lp is not changed
    // function test10_LP() public {
    //   address account = vm.addr(1);
    //   vm.startPrank(deployer);
    //   jdcc.transfer(account, 20000 ether);
    //   jdcc.setFeeWhiteList(account, true);
    //   vm.stopPrank();

    //   addLiquity(account, 100e18); // 100u, 10000jdcc

    //   // uint256 lpAmountBefore = IERC20(mainPair).totalSupply()/10**18;
    //   // vm.startPrank(account);
    //   // vm.warp(block.timestamp + 1 hours);
    //   // jdcc.transfer(account, 0);
    //   // uint256 lpAmountAfter = IERC20(mainPair).totalSupply()/(1 ether);
    //   // assertEq(jdcc.balanceOf(mainPair)/(1 ether), 9925); // jdcc
    //   // assertEq(lpAmountBefore, lpAmountAfter); // lp不变

    //   // vm.warp(block.timestamp + 10 days);
    //   // jdcc.transfer(account, 0);
    //   // assertEq(jdcc.balanceOf(mainPair)/(1 ether), 9205); // jdcc

    //   // vm.warp(block.timestamp + 60 days);
    //   // jdcc.transfer(account, 0);
    //   // assertEq(jdcc.balanceOf(mainPair)/(1 ether), 9205); // jdcc

    //   // vm.warp(block.timestamp + 90 days);
    //   // jdcc.transfer(account, 0);

    //   // vm.warp(block.timestamp + 240 days);
    //   // jdcc.transfer(account, 0);
      
    //   vm.startPrank(account);

    //   uint256 lpAmountBefore = IERC20(mainPair).totalSupply()/(1 ether);

    //   vm.warp(block.timestamp + 1 hours);
    //   jdcc.transfer(account, 0);
    //   assertEq(jdcc.balanceOf(mainPair)/(1 ether), 9925);

    //   vm.warp(block.timestamp + 2200 days);
    //   jdcc.transfer(account, 0);
    //   assertEq(jdcc.balanceOf(mainPair)/(1 ether), 9925);

    //   uint256 lpAmountAfter = IERC20(mainPair).totalSupply()/(1 ether);
    //   assertEq(lpAmountBefore, lpAmountAfter); // lp不变

    //   vm.stopPrank();
    // }

    //  // after auto Deflation，lp is not changed
    // function test11_LpSwap() public {
    //   addLiquity(deployer, 100 ether); // 100u, 10000jdcc

    //   vm.startPrank(deployer);
    //   jdcc.transfer(jdcc.lpDistributor(), 10000 ether);

    //   vm.warp(block.timestamp + 1 hours);
    //   jdcc.transfer(deployer, 0);
   
    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 0);

    //   vm.stopPrank();
    //   ISwapRouter router = ISwapRouter(PancakeRouter);
    //   assertEq(IERC20(router.WETH()).balanceOf(address(jdcc))/(1 ether), 50);


    // }

    // // after auto Deflation，lp is not changed
    // function test12_LpSwap1() public {
    //   vm.startPrank(deployer);

    //   vm.warp(block.timestamp + 1 hours);
    //   jdcc.transfer(deployer, 0);
   
    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 0);

    //   vm.stopPrank();
    // }


  // distributor
    // function test13_DistList() public {
    //   vm.startPrank(deployer);
    //   jdcc.transfer(address(distributor), 1000 ether);
    //   console.log("distributor balanceOf:", jdcc.balanceOf(address(distributor))/ (1 ether));

    //   address[] memory accounts = new address[](2);
    //   accounts[0] = a;
    //   //accounts[1] = b;
    //   distributor.setLch(accounts);
    //   distributor.removeLxList(a);
    //   distributor.setLch(accounts);
    //   distributor.setDaoList(b, 35);
    //   console.log("Lch count:",distributor.lchCount());
    //   console.log("global count:",distributor.GlobalDividendCount());
    //   console.log("Dividend Radio:",distributor.getDividendRadio(b));

      
    //   vm.stopPrank();
    // }

  //  // after auto Deflation，lp is not changed
  //   function test11_LpSwap() public {
  //     addLiquity(deployer, 100 ether); // 100u, 10000jdcc

  //     vm.startPrank(deployer);

  //     jdcc.transfer(jdcc.lpDistributor(), 9000 ether);

  //     vm.warp(block.timestamp + 1 hours);
  //     jdcc.transfer(deployer, 1);
  
  //     vm.warp(block.timestamp + 1 minutes);
  //     jdcc.transfer(deployer, 2);

  //     vm.warp(block.timestamp + 1 days);
  //     jdcc.transfer(deployer, 3);

  //     vm.warp(block.timestamp + 1 minutes);
  //     jdcc.transfer(deployer, 4);

  //     vm.warp(block.timestamp + 1 minutes);
  //     jdcc.transfer(deployer, 4);
  //     vm.stopPrank();
  //   }

    // function test13_GolobalDivendid() public {
    //   vm.startPrank(deployer);
      
    //   jdcc.transfer(address(distributor), 10000 ether);

    //   vm.warp(block.timestamp + 1 hours);
    //   jdcc.transfer(deployer, 1);

    //   address[] memory accounts = new address[](2);
    //   accounts[0]=a;
    //   accounts[1]=b;
    //   distributor.setLch(accounts);

    //   accounts = new address[](1);
    //   accounts[0]=vm.addr(1);
    //   distributor.setSxy(accounts);

    //   accounts = new address[](1);
    //   accounts[0]=vm.addr(2);
    //   distributor.setOp(accounts);

    //   address zong = vm.addr(3);
    //   distributor.setDaoList(zong, 35);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 2);

    //   vm.warp(block.timestamp + 1 days);
    //   jdcc.transfer(deployer, 3);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   // vm.warp(block.timestamp + 1 days);
    //   // jdcc.transfer(deployer, 3);

    //  vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //        vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //        vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.stopPrank();
    //   console.log("lx a:",jdcc.balanceOf(a)/(1 ether));
    //   console.log("lx b:",jdcc.balanceOf(b)/(1 ether));
    //   console.log("zong:",jdcc.balanceOf(zong)/(1 ether));
    // }

    // function test14_GolobalLP() public {
    //   vm.startPrank(deployer);
      
    //   jdcc.transfer(address(distributor), 10000 ether);
    //   jdcc.transfer(address(distributor.reservoir()), 10000 ether);

    //   vm.warp(block.timestamp + 1 hours);
    //   jdcc.transfer(deployer, 1);

    //   address[] memory accounts = new address[](100);
    //   for(uint i=0; i<100; i++) {
    //     address s =vm.addr(i+1);
    //     accounts[i] = s;
    //   }
    //   distributor.setLch(accounts);

    //   address zong = vm.addr(1000);
    //   distributor.setDao(zong, 35);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 2);

    //   vm.warp(block.timestamp + 1 days);
    //   jdcc.transfer(deployer, 3);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   // vm.warp(block.timestamp + 1 days);
    //   // jdcc.transfer(deployer, 3);

    //  vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //        vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //        vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //      vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //      vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //      vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);


    //    vm.warp(block.timestamp + 1 minutes);
    //   jdcc.transfer(deployer, 4);

    //   vm.stopPrank();
    //   for(uint256 i=0; i<100; i++) {
    //   console.log("account:",i,jdcc.balanceOf(vm.addr(i+1))/(1 ether));
    //   }
    //   console.log("zong:",jdcc.balanceOf(zong)/(1 ether));
    // }

  //  function test15_Miner() public {
  //     vm.startPrank(deployer);
  //     jdcc.transfer(a, 10000 ether);
  //     jdcc.transfer(b, 10000 ether);
  //     vm.stopPrank();

  //     addLiquity(a, 100 ether);
  //     addLiquity(b, 100 ether);

  //     vm.startPrank(deployer);
  //     console.log(jdcc.balanceOf(a)/(1 ether));
  //     console.log(jdcc.balanceOf(b)/(1 ether));

  //     address[] memory accounts = new address[](1);
  //     accounts[0] = a;
  //     //accounts[1] = b;
  //     jdcc.setInitLP(accounts);

  //     vm.warp(block.timestamp + 11 minutes);
  //     jdcc.transfer(deployer, 1);
 
  //      vm.warp(block.timestamp + 1 minutes);
  //     jdcc.transfer(deployer, 1);

  //     // vm.warp(block.timestamp + 1 minutes);
  //     // jdcc.transfer(deployer, 2);

  //     // vm.warp(block.timestamp + 1 days);
  //     // jdcc.transfer(deployer, 3);

  //     // vm.warp(block.timestamp + 1 minutes);
  //     // jdcc.transfer(deployer, 4);

  //     // vm.warp(block.timestamp + 1 minutes);
  //     // jdcc.transfer(deployer, 4);

  //     // vm.warp(block.timestamp + 1 minutes);
  //     // jdcc.transfer(deployer, 4);

  //     console.log(jdcc.balanceOf(a)/(1 ether));
  //     //console.log(jdcc.balanceOf(b)/(1 ether));
  // }

//   function test15_LPRward() public {
//       vm.startPrank(deployer);
//       jdcc.transfer(a, 50000 ether);

//       vm.stopPrank();

//       addLiquity(a, 200 ether);
  

//       vm.startPrank(deployer);
//       jdcc.transfer(jdcc.lpDistributor(), 30000 ether);
    
//       address[] memory accounts = new address[](2);
//       accounts[0] = a;
//       accounts[1] = b;
//       jdcc.setInitLP(accounts);

//       vm.warp(block.timestamp + 1 hours);
//       jdcc.transfer(deployer, 1);
 
//       vm.warp(block.timestamp + 1 minutes);
//       jdcc.transfer(deployer, 2);

//       vm.warp(block.timestamp + 1 days);
//       jdcc.transfer(deployer, 3);

//       vm.warp(block.timestamp + 1 minutes);
//       jdcc.transfer(deployer, 4);

//       vm.warp(block.timestamp + 1 minutes);
//       jdcc.transfer(deployer, 4);

//       vm.warp(block.timestamp + 1 minutes);
//       jdcc.transfer(deployer, 4);

//       vm.stopPrank();

//       ISwapRouter router = ISwapRouter(PancakeRouter);
//       console.log(IERC20(router.WETH()).balanceOf(a));
//       console.log(IERC20(router.WETH()).balanceOf(b));
//     }


    function addLiquity(address account, uint256 amount) public {
      ISwapRouter router = ISwapRouter(PancakeRouter);
      //console.log("router:", address(router));

      address tokenA = address(jdcc);
      address tokenB = router.WETH();

        // 模拟巨鲸转账给account一定数量的tokenB（例如，WETH）
        address whale = block.chainid == 56 ? 
                        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c : // BSC主网上的WBNB地址
                        0x57E30beb8054B248CE301FeabfD0c74677Fa40f0; // 测试网络上的WETH地址
        vm.startPrank(whale);
        IERC20(tokenB).transfer(account, amount);
        vm.stopPrank();

        // 模拟account授权Router操作其tokenA和tokenB
        vm.startPrank(account);
        // IERC20(tokenA).approve(address(router), type(uint).max);
        // IERC20(tokenB).approve(address(router), type(uint).max);
        // IERC20(tokenA).approve(mainPair, type(uint).max);
        // IERC20(tokenB).approve(mainPair, type(uint).max);
        IERC20(tokenA).transfer(mainPair, amount*100);
        IERC20(tokenB).transfer(mainPair, amount);
        ISwapPair(mainPair).mint(account);
        //console.log("lpbalance:", IERC20(mainPair).balanceOf(account),
        //IERC20(mainPair).totalSupply());
        // console.log("111:",IERC20(tokenA).balanceOf(account), IERC20(tokenB).balanceOf(account) );

        // console.log("222:",
        // IERC20(tokenA).allowance(account, address(router)), 
        // IERC20(tokenB).allowance(account, address(router)) );
        // 假设account已经有了足够的tokenA
        // 添加流动性
        //  router.addLiquidity(
        //     tokenA,
        //     tokenB,
        //     amount*100, // 假设account希望添加相同数量的tokenA
        //     amount, // 希望添加的tokenB的数量
        //     0,      // slippage是不可避免的，但这里我们为了简化设置为0
        //     0,      // 同上
        //     account, 
        //     block.timestamp + 15 minutes // 截止时间
        // );

        // 执行其他需要的操作，比如断言检查
        vm.stopPrank();

      // vm.prank(account);
        // router.addLiquidity(tokenA,tokenB,amount*100,amount,0,0,
        //     account,
        //     block.timestamp + 15 minutes
        // console.log("lp jdcc balance:",IERC20(tokenA).balanceOf(mainPair)/(10**18));
        // console.log("lp usdt balance:",IERC20(tokenB).balanceOf(mainPair)/(10**18));
    }

    // function removeLiquity(address account) public {
    //   ISwapRouter router = ISwapRouter(PancakeRouter);
    //    address tokenA = address(jdcc);
    //    address tokenB = USDT;

    //   uint amount = IERC20(mainPair).balanceOf(account);

    //   // 授权Router合约从`account`转移LP代币
    //   vm.prank(account);
    //   IERC20(mainPair).approve(address(router), amount);

    //   // 模拟`account`发起移除流动性的操作
    //   vm.prank(account);
    //   router.removeLiquidity(
    //       tokenA,
    //       tokenB,
    //       amount,
    //       0, // 用户愿意接受的最小tokenA数量
    //       0, // 用户愿意接受的最小tokenB数量
    //       account, // 接收tokenA和tokenB的地址
    //       block.timestamp + 15 minutes // 截止时间
    //   );
    // }
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
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);
}


