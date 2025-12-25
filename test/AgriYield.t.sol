// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/KYCRegistry.sol";
import "../src/YieldNoteNFT.sol";
import "../src/AgriVault.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
  constructor() ERC20("Mock USDC", "USDC") {
    _mint(msg.sender, 1_000_000e6);
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }
}

contract AgriYieldTest is Test {
  KYCRegistry kyc;
  YieldNoteNFT yieldNote;
  AgriVault vault;
  MockUSDC usdc;

  address admin = address(this);
  address investor = address(0x1);

  function setUp() public {
    // Deploy mock USDC
    usdc = new MockUSDC();

    // Deploy KYC
    kyc = new KYCRegistry();

    // Whitelist investor
    kyc.approveKYC(investor);

    // Deploy YieldNoteNFT
    yieldNote = new YieldNoteNFT(address(kyc));

    // Deploy Vault
    vault = new AgriVault(
      address(usdc),
      address(kyc),
      address(yieldNote)
    );

    // Fund investor
    usdc.transfer(investor, 10_000e6);
  }

  function testFullFlow() public {
    // --- Mint Yield Note ---
    vm.prank(admin);
    uint256 tokenId = yieldNote.mintYieldNote(
      investor,
      1_000e6,      // principal
      1000,         // 10% yield
      7 days
    );

    // --- Investor deposit ---
    vm.startPrank(investor);
    usdc.approve(address(vault), 1_000e6);
    vault.deposit(tokenId);
    vm.stopPrank();

    // --- Fast forward time ---
    vm.warp(block.timestamp + 8 days);

    // --- Settle ---
    uint256 balanceBefore = usdc.balanceOf(investor);
    vault.settle(tokenId);
    uint256 balanceAfter = usdc.balanceOf(investor);

    // --- Assertions ---
    assertEq(balanceAfter - balanceBefore, 1_100e6);
  }

  function test_Revert_DepositWithoutKYC() public {
    address attacker = address(0x99);

    vm.prank(admin);
    uint256 tokenId = yieldNote.mintYieldNote(
      investor,
      1_000e6,
      500,
      5 days
    );

    vm.prank(attacker);
    vm.expectRevert("KYC required");
    vault.deposit(tokenId); // should revert
  }

  function test_Revert_SettleBeforeMaturity() public {
    vm.prank(admin);
    uint256 tokenId = yieldNote.mintYieldNote(
      investor,
      1_000e6,
      500,
      30 days
    );

    vm.prank(investor);
    usdc.approve(address(vault), 1_000e6);
    vault.deposit(tokenId);

    vm.expectRevert("Not matured");
    vault.settle(tokenId); // should revert
  }
}
