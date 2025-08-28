// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {NftMinting} from "../src/NftMinting.sol";

contract NftMintingTest is Test {
    NftMinting public nftMinting;
    bytes32 merkleRoot;
    address owner = address(0x1);
    address alice = address(0x2);

    function setUp() public {
        string[] memory cmds = new string[](2);
        cmds[0] = "node";
        cmds[1] = "script/generateMerkleRoot";

        bytes memory data = vm.ffi(cmds);
        merkleRoot = abi.decode(data, (bytes32));
        //console.logBytes32(merkleRoot);
        vm.startPrank(owner, owner);
        nftMinting = new NftMinting("http:://ipfs:", merkleRoot);

        vm.deal(owner, 10 ether);
        vm.deal(alice, 10 ether);
    }

    function invariant_supplyCap() public view {
        assert(nftMinting.totalSupply() <= nftMinting.MAX_SUPPLY());
    }

    function test_publicMint() public {
        nftMinting.togglePublicSale();
        vm.stopPrank();

        uint256 nftAmount = 2;
        string[] memory cids = new string[](2);
        cids[0] = "cid1";
        cids[1] = "cid2";

        vm.prank(alice, alice);
        nftMinting.publicSaleMint{value: 0.02 ether}(nftAmount, cids);

        assertEq(nftMinting.ownerOf(0), alice, "Owner of token 1 mismatch");
        assertEq(nftMinting.ownerOf(1), alice, "Owner of token 2 mismatch");
        assertEq(nftMinting.tokenCids(0), "cid1", "Cid 1 mismatch");
        assertEq(nftMinting.tokenCids(1), "cid2", "Cid 2 mismatch");
    }

    function test_withdrawEther() public {
        nftMinting.togglePublicSale();
        vm.stopPrank();

        uint256 nftAmount = 2;
        string[] memory cids = new string[](2);
        cids[0] = "cid1";
        cids[1] = "cid2";

        uint256 preBalanceOwner = address(owner).balance;

        vm.prank(alice, alice);
        nftMinting.publicSaleMint{value: 0.02 ether}(nftAmount, cids);

        vm.prank(owner, owner);
        nftMinting.withdrawEther();

        uint256 postBalanceOwner = address(owner).balance;
        assertEq(postBalanceOwner - preBalanceOwner, 0.02 ether, "Balance Mismatch");
    }

    function test_setCid() public {
        nftMinting.togglePublicSale();
        vm.stopPrank();

        uint256 nftAmount = 1;
        string[] memory cids = new string[](1);
        cids[0] = "cid1";

        vm.prank(alice, alice);
        nftMinting.publicSaleMint{value: 0.01 ether}(nftAmount, cids);
        assertEq(nftMinting.tokenCids(0), "cid1");

        vm.prank(alice);
        nftMinting.setCid(0, "cid0");
        assertEq(nftMinting.tokenCids(0), "cid0");

        vm.prank(owner);
        vm.expectRevert("Owner Mismatch");
        nftMinting.setCid(0, "cid2");
    }

    function test_toggleState() public {
        assert(nftMinting.isPaused() == false);
        assert(nftMinting.isPreSaleActive() == false);
        assert(nftMinting.isPublicSaleActive() == false);

        nftMinting.togglePause();
        nftMinting.togglePreSale();
        nftMinting.togglePublicSale();

        assert(nftMinting.isPaused() == true);
        assert(nftMinting.isPreSaleActive() == true);
        assert(nftMinting.isPublicSaleActive() == true);
    }
}
