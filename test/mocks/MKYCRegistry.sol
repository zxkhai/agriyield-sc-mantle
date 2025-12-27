// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockKYCRegistry {
  mapping(address => bool) private _kycStatus;

  function setKYC(address user, bool status) external {
    _kycStatus[user] = status;
  }

  function isKYCed(address user) external view returns (bool) {
    return _kycStatus[user];
  }
}