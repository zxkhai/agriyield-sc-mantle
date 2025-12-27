// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IKYCRegistry.sol";

contract YieldNoteNFT is ERC721, Ownable {
  
  struct YieldNote {
    uint256 principal;
    uint256 yieldRate;
    uint256 startDate;
    uint256 maturityDate;
    bool settled;
  }

  IKYCRegistry public kycRegistry;
  uint256 public nextTokenId;

  mapping(uint256 => YieldNote) private yieldNotes;

  event YieldNoteMinted(
    address indexed investor,
    uint256 indexed tokenId,
    uint256 principal,
    uint256 yieldRate,
    uint256 maturityDate
  );

  event YieldNoteSettled(uint256 indexed tokenId);

  constructor(address _kycRegistry) ERC721("AgriYield Note", "AYN") Ownable(msg.sender) {
    require(_kycRegistry != address(0), "Invalid KYC registry address");
    kycRegistry = IKYCRegistry(_kycRegistry);
  }

  modifier onlyKYCed(address user) {
    require(kycRegistry.isKYCed(user), "KYC required");
    _;
  }

  // mint a new Yield Note NFT only protocol owner/issuer
  function mintYieldNote(
    address investor,
    uint256 principal,
    uint256 yieldRate,
    uint256 duration
  ) external onlyOwner onlyKYCed(investor) returns (uint256) {
    require(principal > 0, "Invalid Principal");
    require(duration > 0, "Invalid Duration");

    uint256 tokenId = nextTokenId++;
    uint256 maturity = block.timestamp + duration;

    yieldNotes[tokenId] = YieldNote({
      principal: principal,
      yieldRate: yieldRate,
      startDate: block.timestamp,
      maturityDate: maturity,
      settled: false
    });

    _safeMint(investor, tokenId);

    emit YieldNoteMinted(
      investor, 
      tokenId, 
      principal, 
      yieldRate, 
      maturity
    );

    return tokenId;
  }

  // mark a Yield Note as settled (called by Vault later)
  function markAsSettled(uint256 tokenId) external {
    require(_ownerOf(tokenId) != address(0), "Nonexistent token");
    yieldNotes[tokenId].settled = true;
    emit YieldNoteSettled(tokenId);
  }

  // get Yield Note details
  function getYieldNote(uint256 tokenId) external view returns (
    uint256 principal,
    uint256 yieldRate,
    uint256 startDate,
    uint256 maturityDate,
    bool settled
  ) {
    require(_ownerOf(tokenId) != address(0), "Nonexistent token");
    YieldNote memory note = yieldNotes[tokenId];
    return (note.principal, note.yieldRate, note.startDate, note.maturityDate, note.settled);
  }

  // transfer restriction (KYC) - use ERC721 v5 `_update` hook
  function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
    address from = _ownerOf(tokenId);
    if (from != address(0) && to != address(0)) {
      require(kycRegistry.isKYCed(to), "Recipient KYC required");
    }
    return super._update(to, tokenId, auth);
  }
}
