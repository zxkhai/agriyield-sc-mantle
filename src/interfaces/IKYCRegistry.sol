// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IKYCRegistry {
  function isKYCed(address user) external view returns (bool);
}