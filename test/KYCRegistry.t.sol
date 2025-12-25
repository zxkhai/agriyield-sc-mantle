// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {KYCRegistry} from "../src/KYCRegistry.sol";

contract KYCRegistryTest is Test {
  KYCRegistry public kyc;
  
  address owner = address(0xABCD);
  address user = address(0x1234);
  address newOwner = address(0xDEAD);

  function setUp() public {
    vm.prank(owner);
    kyc = new KYCRegistry();
  }

  function testInitialOwner() public {
    assertEq(kyc.owner(), owner);
  }

  function testApproveKYC() public {
    vm.prank(owner);
    kyc.approveKYC(user);
    assertTrue(kyc.isKYCed(user));
  }

  function testRevokeKYC() public {
    vm.startPrank(owner);
    kyc.approveKYC(user);
    kyc.revokeKYC(user);
    assertFalse(kyc.isKYCed(user));
    vm.stopPrank();
  }

  function testApproveKYC_NotOwner() public {
    vm.prank(user);
    vm.expectRevert("Not the owner");
    kyc.approveKYC(user);
  }

  function testRevokeKYC_NotOwner() public {
    vm.prank(user);
    vm.expectRevert("Not the owner");
    kyc.revokeKYC(user);
  }

  function testTransferOwnership() public {
    vm.prank(owner);
    kyc.transferOwnership(newOwner);
    assertEq(kyc.owner(), newOwner);
  }

  function testTransferOwnership_NotOwner() public {
    vm.prank(user);
    vm.expectRevert("Not the owner");
    kyc.transferOwnership(newOwner);
  }

  function testApproveKYC_InvalidAddress() public {
    vm.prank(owner);
    vm.expectRevert("Invalid address");
    kyc.approveKYC(address(0));
  }

  function testRevokeKYC_InvalidAddress() public {
    vm.prank(owner);
    vm.expectRevert("Invalid address");
    kyc.revokeKYC(address(0));
  }

  function testTransferOwnership_InvalidAddress() public {
    vm.prank(owner);
    vm.expectRevert("Invalid address");
    kyc.transferOwnership(address(0));
  }
}
