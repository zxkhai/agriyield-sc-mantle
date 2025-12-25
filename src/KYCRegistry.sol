// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract KYCRegistry {
  address public owner;

  mapping(address => bool) private _isKYCed;

  event KYCApproved(address indexed user);
  event KYCRevoked(address indexed user);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
  }

  modifier onlyKYCed(address user) {
    require(_isKYCed[user], "KYC not completed");
    _;
  }

  constructor() {
      owner = msg.sender;
  }

  // approve KYC for a user
  function approveKYC(address user) external onlyOwner {
    require(user != address(0), "Invalid address");
    _isKYCed[user] = true;
    emit KYCApproved(user);
  }

  // revoke KYC for a user
  function revokeKYC(address user) external onlyOwner {
    require(user != address(0), "Invalid address");
    _isKYCed[user] = false;
    emit KYCRevoked(user);
  }

  // check if a user is KYCed
  function isKYCed(address user) external view returns (bool) {
    return _isKYCed[user];
  }

  // transfer ownership of the contract
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Invalid address");
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}