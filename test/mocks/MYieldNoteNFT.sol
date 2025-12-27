// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockYieldNoteNFT {
  struct YieldNote {
    uint256 principal;
    uint256 yieldRate;
    uint256 startDate;
    uint256 maturityDate;
    bool settled;
  }

  mapping(uint256 => address) private _owners;
  mapping(uint256 => YieldNote) private _yieldNotes;
  uint256 private _nextTokenId;

  function mint(address to, uint256 tokenId, uint256 principal, uint256 yieldRate, uint256 maturity) external {
    _owners[tokenId] = to;
    _yieldNotes[tokenId] = YieldNote(principal, yieldRate, block.timestamp, maturity, false);
    _nextTokenId = tokenId + 1;
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    return _owners[tokenId];
  }

  function getYieldNote(uint256 tokenId) external view returns (
    uint256 principal,
    uint256 yieldRate,
    uint256 startDate,
    uint256 maturityDate,
    bool settled
  ) {
    YieldNote memory note = _yieldNotes[tokenId];
    return (note.principal, note.yieldRate, note.startDate, note.maturityDate, note.settled);
  }

  function markAsSettled(uint256 tokenId) external {
    _yieldNotes[tokenId].settled = true;
  }

  function setSettled(uint256 tokenId, bool status) external {
    _yieldNotes[tokenId].settled = status;
  }
}