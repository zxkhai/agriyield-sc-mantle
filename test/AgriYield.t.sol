// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/KYCRegistry.sol";
import "../src/YieldNoteNFT.sol";
import "../src/AgriVault.sol";

contract AgriYieldTest is Test {
  KYCRegistry kycRegistry;
  YieldNoteNFT yieldNoteNFT;
  AgriVault agriVault;

  address owner = address(1);
  address investor1 = address(2);
  address investor2 = address(3);
  address nonKYCed = address(4);

  uint256 tokenId1;
  uint256 tokenId2;

  function setUp() public {
    // Deploy contracts
    vm.prank(owner);
    kycRegistry = new KYCRegistry();

    vm.prank(owner);
    yieldNoteNFT = new YieldNoteNFT(address(kycRegistry));

    vm.prank(owner);
    agriVault = new AgriVault(address(kycRegistry), address(yieldNoteNFT));

    // Fund the vault with ETH for payouts
    vm.deal(address(agriVault), 100 ether);

    // Approve KYC for investors
    vm.prank(owner);
    kycRegistry.approveKYC(investor1);
    vm.prank(owner);
    kycRegistry.approveKYC(investor2);
  }

  function testFullYieldNoteLifecycle() public {
    // 1. Mint a yield note
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(
      investor1,
      1000, // principal
      500,  // yield rate (5%)
      365 days // duration
    );

    // Verify NFT ownership
    assertEq(yieldNoteNFT.ownerOf(tokenId1), investor1);

    // Verify yield note details
    (
      uint256 principal,
      uint256 yieldRate,
      uint256 startDate,
      uint256 maturityDate,
      bool settled
    ) = yieldNoteNFT.getYieldNote(tokenId1);

    assertEq(principal, 1000);
    assertEq(yieldRate, 500);
    assertEq(maturityDate, startDate + 365 days);
    assertFalse(settled);

    // 2. Investor deposits principal
    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    // Verify deposit
    assertTrue(agriVault.funded(tokenId1));

    // 3. Fast forward to maturity
    vm.warp(block.timestamp + 366 days);

    // 4. Settle the yield note
    vm.prank(owner);
    agriVault.settle(tokenId1);

    // Verify settlement
    (
      ,
      ,
      ,
      ,
      bool settledAfter
    ) = yieldNoteNFT.getYieldNote(tokenId1);
    assertTrue(settledAfter);

    // Verify payout (investor should have received 1000 + 50 = 1050)
    assertEq(investor1.balance, 1050);
  }

  function testMultipleInvestors() public {
    // Mint notes for two investors
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(owner);
    tokenId2 = yieldNoteNFT.mintYieldNote(investor2, 2000, 300, 365 days);

    // Both deposit
    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    vm.prank(investor2);
    agriVault.deposit(tokenId2);

    // Fast forward and settle both
    vm.warp(block.timestamp + 366 days);

    vm.prank(owner);
    agriVault.settle(tokenId1);

    vm.prank(owner);
    agriVault.settle(tokenId2);

    // Verify payouts
    assertEq(investor1.balance, 1050); // 1000 + 50
    assertEq(investor2.balance, 2060); // 2000 + 60
  }

  function testTransferYieldNote() public {
    // Mint note for investor1
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    // Transfer to investor2
    vm.prank(investor1);
    yieldNoteNFT.transferFrom(investor1, investor2, tokenId1);

    // Verify ownership
    assertEq(yieldNoteNFT.ownerOf(tokenId1), investor2);

    // investor2 should be able to deposit
    vm.prank(investor2);
    agriVault.deposit(tokenId1);

    assertTrue(agriVault.funded(tokenId1));
  }

  function testNonKYCedCannotMint() public {
    vm.prank(owner);
    vm.expectRevert("KYC required");
    yieldNoteNFT.mintYieldNote(nonKYCed, 1000, 500, 365 days);
  }

  function testNonKYCedCannotDeposit() public {
    // Mint for KYCed investor first
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    // Revoke KYC
    vm.prank(owner);
    kycRegistry.revokeKYC(investor1);

    // Try to deposit
    vm.prank(investor1);
    vm.expectRevert("KYC required");
    agriVault.deposit(tokenId1);
  }

  function testCannotDepositTwice() public {
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    vm.prank(investor1);
    vm.expectRevert("Already funded");
    agriVault.deposit(tokenId1);
  }

  function testCannotSettleBeforeMaturity() public {
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    vm.prank(owner);
    vm.expectRevert("Not matured");
    agriVault.settle(tokenId1);
  }

  function testCannotSettleUnfunded() public {
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(owner);
    vm.expectRevert("Not funded");
    agriVault.settle(tokenId1);
  }

  function testCannotSettleTwice() public {
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    vm.warp(block.timestamp + 366 days);

    vm.prank(owner);
    agriVault.settle(tokenId1);

    vm.prank(owner);
    vm.expectRevert("Already settled");
    agriVault.settle(tokenId1);
  }

  function testOnlyOwnerCanSettle() public {
    vm.prank(owner);
    tokenId1 = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    agriVault.deposit(tokenId1);

    vm.warp(block.timestamp + 366 days);

    vm.prank(investor1);
    vm.expectRevert("Not owner");
    agriVault.settle(tokenId1);
  }

  function testYieldCalculation() public {
    // Test different yield rates
    vm.prank(owner);
    uint256 tokenIdA = yieldNoteNFT.mintYieldNote(investor1, 1000, 1000, 365 days); // 10% yield

    vm.prank(owner);
    uint256 tokenIdB = yieldNoteNFT.mintYieldNote(investor2, 1000, 500, 365 days);  // 5% yield

    vm.prank(investor1);
    agriVault.deposit(tokenIdA);

    vm.prank(investor2);
    agriVault.deposit(tokenIdB);

    vm.warp(block.timestamp + 366 days);

    vm.prank(owner);
    agriVault.settle(tokenIdA);

    vm.prank(owner);
    agriVault.settle(tokenIdB);

    // investor1 should get 1000 + 100 = 1100 (10% yield)
    // investor2 should get 1000 + 50 = 1050 (5% yield)
    assertEq(investor1.balance, 1100);
    assertEq(investor2.balance, 1050);
  }

  function testContractOwnership() public {
    // Test that contracts have correct owners
    assertEq(kycRegistry.owner(), owner);
    assertEq(yieldNoteNFT.owner(), owner);
    assertEq(agriVault.owner(), owner);
  }

  function testKYCManagement() public {
    // Test KYC approval and revocation
    assertTrue(kycRegistry.isKYCed(investor1));

    vm.prank(owner);
    kycRegistry.revokeKYC(investor1);
    assertFalse(kycRegistry.isKYCed(investor1));

    vm.prank(owner);
    kycRegistry.approveKYC(investor1);
    assertTrue(kycRegistry.isKYCed(investor1));
  }
}