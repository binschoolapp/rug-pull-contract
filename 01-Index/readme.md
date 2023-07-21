土狗合约 概述
学习时间：30分钟
本章讲解土狗合约的基本知识，识别土狗的欺诈手段汇总，掌握反欺诈的常用方法。

视频：Bilibili  |  Youtube

代码：github.com/binschoolapp/rug-pull-contract
推特：@BinSchoolApp    Discord：BinSchoolApp   微信：bkra50 
币圈常说的“土狗合约”，是指一种欺诈性的智能合约，其设计目的是骗取投资者的资金。

土狗合约的英文名称是 "Rug Pull Contract"，直译过来就是 “抽地毯合约”。

意思是在投资者毫无准备的情况下，合约的创建者快速地将所有资金“拔出”，使得投资者无法继续访问或回收自有资金。“土狗合约” 在大多数情况下，是一个精心设计的骗局，最终的结果就是 “卷包会”。

"土狗合约" 通常是指 ERC20 代币合约，但其中精心设计了一些陷阱或后门。

欺诈者使用这些代币合约创建代币，并通过各种营销手段，比如通过电报、推特、微信等社交媒体平台上的 KOL，也就是意见领袖、网红大V进行喊单，并不断拉升价格，吸引投资者购买这些代币。一旦投资者上当后，他们会利用合约中的后门或陷阱，将投资者的资金彻底卷走，留给投资者一地鸡毛。

互联网世界非常魔幻，越是最罪恶的地方，技术也最为先进。比如，成人金色网站通常是互联网最新技术的先驱者和集大成者，什么高并发技术、视频压缩算法、ai技术、ar/vr技术，都被首先应用其中，甚至元宇宙都有可能在这个领域内率先实现。

土狗合约也差不多是这种情况，它在智能合约中属于技术含量比较高的，很多土狗合约的陷阱设计得极其巧妙，把 solidity 编程技巧运用得虎虎生风、出神入化。

我这里整理了一系列典型的土狗合约设计案例，很多都是链上的实际案例。通过这些案例，我们可以学习到智能合约的设计思路，以及智能合约和DApp的开发过程。

涉及到的知识包括：solidity 语言、ERC20 合约、Swap 合约等。

欺诈手段汇总
土狗合约的欺诈手段非常多，至少有几十种。

这里总结了一些土狗合约主要的欺诈手段，包括：

使用代理合约
预留自毁合约
函数签名欺诈
调用外部合约
貔貅代币
限制代币卖出
存在暂停交易功能
存在交易冷却功能
存在黑名单
存在白名单
不合理交易税
针对特定地址改税
内置防巨鲸功能
欺骗巨鲸追随者
套路机器人
存在增发功能
可重获所有权
Owner可改余额
批量Meme骗局
资金盘骗局
倾销砸盘
移除流动性
我会通过一系列的文章和视频，分析以上这些骗局，防止受到欺诈。

另外，我整理一些正常的综合了 ERC20 和 Swap 的合约，这都是为别人开发 DApp 积累的项目，具有非常高的实用价值，有一定编程基础的小伙伴可用于学习。

我已经把这些代码开放到网站和 GitHub 上，如果对您有用的话，可以 Star 一下。

地址为：

ERC20 合约
我们首先要学会编写一个 ERC20 合约，也就是代币合约。

实际上，这非常简单，因为 OpenZeppelin 已经为我们实现了 ERC20 的标准合约。

我们只需要继承 OpenZeppelin 提供的 ERC20 标准合约，并修改构造函数的几个参数就可以了，无需从头开始编写。

完整的发币代码只需几行即可实现。

这是一个简单的代币合约的例子：

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyCoin", "MC") {
        _mint(msg.sender, 100*10**18);
    }
}
我们只需要用几行代码，就发行了一个名称为 MyCoin 的代币。

其实真正有效的就是屏幕上圈出的3行代码。

contract MyToken is ERC20 {
上面代码，表示这个合约继承了 OpenZeppelin 的 ERC20 合约。

constructor() ERC20("MyCoin", "MC") { 
上面代码，表示发行的代币名称为 MyCoin，代码为 MC。

_mint(msg.sender, 100*10**18);
上面代码，表示发行总量为100个，并将发行的代币分配给合约创建者。

您可以把这份代码部署到 Remix，查看效果。

后面我们讲的土狗合约，都是基于 ERC20 的代币合约。

绕过锁定期的土狗合约
我们下面研究一个简单的土狗合约。

一个合约创建者发布了一个土狗合约，然后承诺发行的部分代币锁定期为1年。这样的好处就是短期内不会有大量代币砸出，可以维持恒定的价格。另外也给投资者信心，就是项目方短期内不会跑路，因为他筹码被锁定了，要跑也是一年后的事情。

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

在这个合约中，锁定期 lockTime 设定为365天。

owner用来存放合约创建者地址。

我们专门编写了一个修饰器 lock，用来判断合约创建者持币是否满足1年。

只有到期后，才允许执行后续操作，如果没有到期，直接回滚交易，不允许后续操作。

代币合约中的转账操作 transfer, 加上了修饰器 lock，用来确保合约创建者的代币在锁定1年后，才能进行转账。

这个土狗合约的创建者如何能够提前拿走代币呢，它的后门是什么？您可以仔细想一想。

我们会在下一期视频中进行分析，并会介绍后续的一些欺诈手段。

视频中所有代码都在网站和 github 上，您可以自己复制使用。