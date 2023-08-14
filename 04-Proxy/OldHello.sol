// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHello {
  function greet() external pure returns(string memory);
}

contract Proxy {
  address helloAddress;

  function setHello(address _helloAddress) external {
    helloAddress = _helloAddress;
  }

  function greet() external view returns(string memory) { 
    return IHello(helloAddress).greet();
  } 
}