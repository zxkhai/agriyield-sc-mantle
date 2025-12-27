// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../../src/AgriVault.sol";
import "../mocks/MKYCRegistry.sol";
import "../mocks/MYieldNoteNFT.sol";

contract FailingReceiver {
  receive() external payable {
    revert("Receive failed");
  }
}

contract AgriVaultTest is Test {
  AgriVault vault;
  MockKYCRegistry mockKYC;
  MockYieldNoteNFT mockNFT;
  address owner = address(1);
  address investor1 = address(2);
  address investor2 = address(3);
  address nonOwner = address(4);
  address nonKYCed = address(5);
  FailingReceiver failingReceiver;

  function setUp() public {
    vm.prank(owner);
    mockKYC = new MockKYCRegistry();
    vm.prank(owner);
    mockNFT = new MockYieldNoteNFT();
    vm.prank(owner);
    vault = new AgriVault(address(mockKYC), address(mockNFT));
    failingReceiver = new FailingReceiver();
  }

  function testConstructor() public {
    assertEq(address(vault.kycRegistry()), address(mockKYC));
    assertEq(address(vault.yieldNoteNFT()), address(mockNFT));
    assertEq(vault.owner(), owner);
  }

  function testConstructorZeroKYC() public {
    vm.prank(owner);
    vm.expectRevert("Invalid KYC");
    new AgriVault(address(0), address(mockNFT));
  }

  function testConstructorZeroNFT() public {
    vm.prank(owner);
    vm.expectRevert("Invalid YieldNote");
    new AgriVault(address(mockKYC), address(0));
  }

  function testDeposit() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    assertTrue(vault.funded(0));
  }

  function testDepositNotKYCed() public {
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vm.expectRevert("KYC required");
    vault.deposit(0);
  }

  function testDepositAlreadyFunded() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    vm.prank(investor1);
    vm.expectRevert("Already funded");
    vault.deposit(0);
  }

  function testDepositNotOwner() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor2, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor2);
    vm.expectRevert("Not the owner");
    vault.deposit(0);
  }

  function testDepositSettled() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);
    vm.prank(address(mockNFT));
    mockNFT.setSettled(0, true);

    vm.prank(investor1);
    vm.expectRevert("Already settled");
    vault.deposit(0);
  }

  function testSettle() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    vm.warp(block.timestamp + 366 days);

    vm.deal(address(vault), 1500); // Fund vault with enough ETH

    vm.prank(owner);
    vault.settle(0);

    // Check that NFT is marked as settled
    (, , , , bool settled) = mockNFT.getYieldNote(0);
    assertTrue(settled);
  }

  function testSettleNotFunded() public {
    vm.prank(owner);
    vm.expectRevert("Not funded");
    vault.settle(0);
  }

  function testSettleAlreadySettled() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    vm.warp(block.timestamp + 366 days);

    vm.prank(address(mockNFT));
    mockNFT.setSettled(0, true);

    vm.prank(owner);
    vm.expectRevert("Already settled");
    vault.settle(0);
  }

  function testSettleNotMatured() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    vm.prank(owner);
    vm.expectRevert("Not matured");
    vault.settle(0);
  }

  function testSettleNotOwner() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockNFT));
    mockNFT.mint(investor1, 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(investor1);
    vault.deposit(0);

    vm.warp(block.timestamp + 366 days);

    vm.prank(nonOwner);
    vm.expectRevert("Not owner");
    vault.settle(0);
  }

  function testSettlePayoutFailure() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(address(failingReceiver), true);
    vm.prank(address(mockNFT));
    mockNFT.mint(address(failingReceiver), 0, 1000, 500, block.timestamp + 365 days);

    vm.prank(address(failingReceiver));
    vault.deposit(0);

    vm.warp(block.timestamp + 366 days);

    vm.deal(address(vault), 1500);

    vm.prank(owner);
    vm.expectRevert("Payout failed");
    vault.settle(0);
  }
}