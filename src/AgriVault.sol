// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface IKYCRegistry {
  function isKYCed(address user) external view returns (bool);
}

interface IYieldNoteNFT {
  function ownerOf(uint256 tokenId) external view returns (address);
  function getYieldNote(uint256 tokenId) external view returns (
    uint256 principal,
    uint256 yieldRate,
    uint256 startDate,
    uint256 maturityDate,
    bool settled
  );
  function markAsSettled(uint256 tokenId) external;
}

contract AgriVault is ReentrancyGuard {
  IKYCRegistry public immutable kycRegistry;
  IYieldNoteNFT public immutable yieldNoteNFT;

  address public owner;

  mapping(uint256 => bool) public funded;

  event Deposited(address indexed investor, uint256 indexed tokenId, uint256 amount);
  event Settled(
    address indexed investor,
    uint256 indexed tokenId,
    uint256 principal,
    uint256 yieldAmount
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyKYCed(address user) {
    require(kycRegistry.isKYCed(user), "KYC required");
    _;
  }

  constructor (address _kycRegistry, address _yieldNoteNFT) {
    require(_kycRegistry != address(0), "Invalid KYC");
    require(_yieldNoteNFT != address(0), "Invalid YieldNote");

    kycRegistry = IKYCRegistry(_kycRegistry);
    yieldNoteNFT = IYieldNoteNFT(_yieldNoteNFT);

    owner = msg.sender;
  }

  // investor deposits principal for a Yield Note
  function deposit(uint256 tokenId) external nonReentrant onlyKYCed(msg.sender) {
    require(!funded[tokenId], "Already funded");
    require(yieldNoteNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
    (
      uint256 principal,
      ,
      ,
      ,
      bool settled
    ) = yieldNoteNFT.getYieldNote(tokenId);

    require(!settled, "Already settled");

    funded[tokenId] = true;

    emit Deposited(msg.sender, tokenId, principal);
  }

  function settle(uint256 tokenId) external nonReentrant onlyOwner {
    require(funded[tokenId], "Not funded");

    (
      uint256 principal,
      uint256 yieldRate,
      ,
      uint256 maturity,
      bool settled
    ) = yieldNoteNFT.getYieldNote(tokenId);

    require(!settled, "Already settled");
    require(block.timestamp >= maturity, "Not matured");

    address investor = yieldNoteNFT.ownerOf(tokenId);

    uint256 yieldAmount = (principal * yieldRate) / 10_000;
    uint256 totalPayout = principal + yieldAmount;

    yieldNoteNFT.markAsSettled(tokenId);

    (bool success, ) = investor.call{value: totalPayout}("");
    require(success, "Payout failed");

    emit Settled(investor, tokenId, principal, yieldAmount);
  }
}
