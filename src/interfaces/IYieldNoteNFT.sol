// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

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