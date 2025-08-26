// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {NftMinting} from "../src/NftMinting.sol";

contract NftMintingTest is Test {
    NftMinting public nftMinting;

    function setUp() public {
        bytes32 merkleRoot;
        string[] memory cmds= new string[](2);
        cmds[0]= "node";
        cmds[1]= "script/generateMerkleRoot";
        
        bytes memory data= vm.ffi(cmds);
        merkleRoot= abi.decode(data,(bytes32));
        console.logBytes32(merkleRoot);
    }

    function testIncrement() public {}
}
