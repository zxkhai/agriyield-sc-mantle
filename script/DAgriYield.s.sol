// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/KYCRegistry.sol";
import "../src/YieldNoteNFT.sol";
import "../src/AgriVault.sol";

contract DeployAgriYield is Script {
  function run() external {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerPrivateKey);

    // Deploy KYCRegistry first
    KYCRegistry kycRegistry = new KYCRegistry();
    console.log("KYCRegistry deployed at:", address(kycRegistry));

    // Deploy YieldNoteNFT with KYCRegistry address
    YieldNoteNFT yieldNoteNFT = new YieldNoteNFT(address(kycRegistry));
    console.log("YieldNoteNFT deployed at:", address(yieldNoteNFT));

    // Deploy AgriVault with both addresses
    AgriVault agriVault = new AgriVault(address(kycRegistry), address(yieldNoteNFT));
    console.log("AgriVault deployed at:", address(agriVault));

    // Stop broadcasting
    vm.stopBroadcast();

    // Log deployment summary
    console.log("\n=== Deployment Summary ===");
    console.log("KYCRegistry:", address(kycRegistry));
    console.log("YieldNoteNFT:", address(yieldNoteNFT));
    console.log("AgriVault:", address(agriVault));
    console.log("Deployer:", vm.addr(deployerPrivateKey));
    console.log("Network:", block.chainid);
  }
}