// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../../src/KYCRegistry.sol";

contract KYCRegistryTest is Test {
    KYCRegistry registry;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);
    address nonOwner = address(4);

    function setUp() public {
        vm.prank(owner);
        registry = new KYCRegistry();
    }

    function testConstructor() public {
        assertEq(registry.owner(), owner);
    }

    function testApproveKYC() public {
        vm.prank(owner);
        registry.approveKYC(user1);
        assertTrue(registry.isKYCed(user1));
    }

    function testApproveKYCZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        registry.approveKYC(address(0));
    }

    function testApproveKYCNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        registry.approveKYC(user1);
    }

    function testApproveKYCAlreadyApproved() public {
        vm.prank(owner);
        registry.approveKYC(user1);
        vm.prank(owner);
        registry.approveKYC(user1); // Should not revert, just set again
        assertTrue(registry.isKYCed(user1));
    }

    function testRevokeKYC() public {
        vm.prank(owner);
        registry.approveKYC(user1);
        vm.prank(owner);
        registry.revokeKYC(user1);
        assertFalse(registry.isKYCed(user1));
    }

    function testRevokeKYCZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        registry.revokeKYC(address(0));
    }

    function testRevokeKYCNotApproved() public {
        vm.prank(owner);
        registry.revokeKYC(user1); // Should not revert, just set to false
        assertFalse(registry.isKYCed(user1));
    }

    function testRevokeKYCNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        registry.revokeKYC(user1);
    }

    function testIsKYCed() public {
        assertFalse(registry.isKYCed(user1));
        vm.prank(owner);
        registry.approveKYC(user1);
        assertTrue(registry.isKYCed(user1));
    }

    function testTransferOwnership() public {
        vm.prank(owner);
        registry.transferOwnership(user1);
        assertEq(registry.owner(), user1);
    }

    function testTransferOwnershipZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        registry.transferOwnership(address(0));
    }

    function testTransferOwnershipNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        registry.transferOwnership(user1);
    }

    function testTransferOwnershipToSelf() public {
        vm.prank(owner);
        registry.transferOwnership(owner);
        assertEq(registry.owner(), owner);
    }
}