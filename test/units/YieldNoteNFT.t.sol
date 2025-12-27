// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../../src/YieldNoteNFT.sol";
import "../mocks/MKYCRegistry.sol";

contract YieldNoteNFTTest is Test {
  YieldNoteNFT yieldNoteNFT;
  MockKYCRegistry mockKYC;
  address owner = address(1);
  address investor1 = address(2);
  address investor2 = address(3);
  address nonOwner = address(4);
  address nonKYCed = address(5);

  function setUp() public {
    vm.prank(owner);
    mockKYC = new MockKYCRegistry();
    vm.prank(owner);
    yieldNoteNFT = new YieldNoteNFT(address(mockKYC));
  }

  function testConstructor() public {
    assertEq(address(yieldNoteNFT.kycRegistry()), address(mockKYC));
    assertEq(yieldNoteNFT.owner(), owner);
  }

  function testConstructorZeroAddress() public {
    vm.prank(owner);
    vm.expectRevert("Invalid KYC registry address");
    new YieldNoteNFT(address(0));
  }

  function testMintYieldNote() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(owner);
    uint256 tokenId = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    assertEq(yieldNoteNFT.ownerOf(tokenId), investor1);
    assertEq(yieldNoteNFT.nextTokenId(), 1);

    (
        uint256 principal,
        uint256 yieldRate,
        uint256 startDate,
        uint256 maturityDate,
        bool settled
    ) = yieldNoteNFT.getYieldNote(tokenId);

    assertEq(principal, 1000);
    assertEq(yieldRate, 500);
    assertEq(startDate, block.timestamp);
    assertEq(maturityDate, block.timestamp + 365 days);
    assertFalse(settled);
  }

  function testMintYieldNoteZeroPrincipal() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(owner);
    vm.expectRevert("Invalid Principal");
    yieldNoteNFT.mintYieldNote(investor1, 0, 500, 365 days);
  }

  function testMintYieldNoteZeroDuration() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(owner);
    vm.expectRevert("Invalid Duration");
    yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 0);
  }

  function testMintYieldNoteNotOwner() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(nonOwner);
    vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
    yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);
  }

  function testMintYieldNoteNotKYCed() public {
    vm.prank(owner);
    vm.expectRevert("KYC required");
    yieldNoteNFT.mintYieldNote(nonKYCed, 1000, 500, 365 days);
  }

  function testMarkAsSettled() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(owner);
    uint256 tokenId = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    yieldNoteNFT.markAsSettled(tokenId);

    (
      ,
      ,
      ,
      ,
      bool settled
    ) = yieldNoteNFT.getYieldNote(tokenId);

    assertTrue(settled);
  }

  function testMarkAsSettledNonExistent() public {
    vm.expectRevert("Nonexistent token");
    yieldNoteNFT.markAsSettled(999);
  }

  function testGetYieldNoteNonExistent() public {
    vm.expectRevert("Nonexistent token");
    yieldNoteNFT.getYieldNote(999);
  }

  function testTransferToKYCed() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor2, true);

    vm.prank(owner);
    uint256 tokenId = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    yieldNoteNFT.transferFrom(investor1, investor2, tokenId);

    assertEq(yieldNoteNFT.ownerOf(tokenId), investor2);
  }

  function testTransferToNonKYCed() public {
    vm.prank(address(mockKYC));
    mockKYC.setKYC(investor1, true);

    vm.prank(owner);
    uint256 tokenId = yieldNoteNFT.mintYieldNote(investor1, 1000, 500, 365 days);

    vm.prank(investor1);
    vm.expectRevert("Recipient KYC required");
    yieldNoteNFT.transferFrom(investor1, nonKYCed, tokenId);
  }

  function testTransferNonExistent() public {
    vm.prank(investor1);
    vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999));
    yieldNoteNFT.transferFrom(investor1, investor2, 999);
  }
}