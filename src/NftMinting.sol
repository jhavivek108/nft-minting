// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NftMinting is ERC721, ReentrancyGuard, PaymentSplitter, Ownable {
    bytes32 public immutable merkelRoot;
    uint256 public constant PRESALE_LIMIT = 5;
    uint256 public constant NFT_MINTING_PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 20;

    bool public isPaused;
    bool public isPreSaleActive;
    bool public isPublicSaleActive;

    uint256 private _currentTokenID;

    string private _baseTokenURI;
    mapping(uint256 => string) public tokenCids;

    mapping(address => uint256) public presaleCount;
    address[] private _teamMembers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    ];

    uint256[] private _teamShares = [20, 30, 50];

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA are allowed");
        _;
    }

    modifier isVerified(bytes32[] calldata proof) {
        require(MerkelProof.verify(proof, merkelRoot, keccak256(abi.encodePacked((msg.sender)))), "Proof not valid");
        _;
    }
}
