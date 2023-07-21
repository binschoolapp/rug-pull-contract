# 土狗合约欺诈与反欺诈

## 1. HoldAutoCI，持币自动复利

**功能：持币自动计算复利，交易收税，营销钱包分U，销毁代币**

- 买税8%，卖税8%

- 持币自动复利2.5%

- 买入8%邀请奖励（分别为3%、1%、0.5%、0.5%、0.5%、0.5%、0.5%、0.5%、0.5%、0.5%，奖励直接发放到钱包）

- 1%回流添加池子，1%营销，1%销毁，5%营销

- 营销钱包分U

**项目地址：**
https://github.com/binschoolapp/rug-pull-contract/blob/main/99-Template/HoldAutoCI.sol

## 2. AddUsdtLP，回流USDT池子

**功能：USDT 回流加池子，营销钱包，销毁**

- 买卖10%滑点，3%销毁，3%回流筑池（1.5%币、1.5%U），3%LP分红 DAPP实现，1%基金会（U到账）

**项目地址：**

https://github.com/binschoolapp/rug-pull-contract/blob/main/99-Template/AddUsdtLP.sol

## 3. HoldDividendBNB，持币分红 BNB

**功能：6% 持币分红 BNB，2% 营销钱包 BNB**

- 买卖、转账都有 8% 滑点，6% 给持币分红 BNB，2% 营销钱包 BNB

- 持有200万币才能参与分红

- 卖不干净，最少留 0.1 币

**项目地址：**

https://github.com/binschoolapp/rug-pull-contract/blob/main/99-Template/HoldDividendBNB.sol

## 4. RebaseDividendToken，Rebase 分红本币

**功能：4% 持币分红本币，1% 营销钱包本币**

- 买卖5%滑点，4%给持币分红，1%营销钱包

- 未开启交易时，只能项目方加池子，加池子未开放交易，机器人购买高滑点

- 手续费白名单，分红排除名单

**项目地址：**

https://github.com/binschoolapp/rug-pull-contract/blob/main/99-Template/RebaseDividend.sol

## 5. LPDividendUsdt，加LP分红

**功能： 加 LP 分红 USDT，推荐关系绑定，推荐分红本币，营销钱包，限购，自动杀区块机器人**

- 买卖14%滑点，3%给加LP池子分红，4%分配10级推荐，1%营销钱包，1%备用拉盘，5%进入NFT盲盒>
- 推荐分红，1级0.48%,2级0.44%,3级0.42%，4-10级各0.38%
- 限购总量 1%<br>

**项目地址：**

https://github.com/binschoolapp/rug-pull-contract/blob/main/ERC20/LPDividend.sol

