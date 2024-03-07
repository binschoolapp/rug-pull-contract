// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapRouter {
    address public addr;
    function setAddress(address _addr) public {
        addr = _addr;
    }
    function getAddress() public view returns(address){
        return addr;
    }
    function factory() public view returns (address) {
      return addr;
    }
}

contract SwapFactory {
    address public addr;
    function createPair(address tokenA, address tokenB) external view returns (address){
      require(tokenA != address(0) && tokenB != address(0));
      return addr;
    }

    function setAddress(address _addr) public {
        addr = _addr;
    }

    function getAddress() public view returns(address){
        return addr;
    }
}

contract SwapPair is ERC20{
    uint private foo;
    constructor() ERC20("pair","pair") {
        _mint(address(this), 300);
    }
    function sync() external {
      foo = 100;
    }
}