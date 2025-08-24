// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NftMinting is ERC721, ReentrancyGuard, PaymentSplitter, Ownable {
    bytes32 public immutable merkleRoot;
    uint256 public constant PRESALE_LIMIT = 5;
    uint256 public constant NFT_MINTING_PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 200;

    bool public isPaused;
    bool public isPreSaleActive;
    bool public isPublicSaleActive;

    uint256 private _currentTokenID;

    string private _baseTokenURI;
    mapping(uint256 => string) public tokenCids;

    mapping(address => uint256) public preSaleCount;
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
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Proof not valid");
        _;
    }

    constructor(string memory initialBaseURI, bytes32 root)
        ERC721("New NFT", "NNFT")
        Ownable()
        ReentrancyGuard()
        PaymentSplitter(_teamMembers, _teamShares)
    {
        _baseTokenURI = initialBaseURI;
        merkleRoot = root;
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    function togglePreSale() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function preSaleMint(uint256 nftAmount, bytes32[] calldata proof, string[] calldata cids)
        external
        payable
        onlyEOA
        nonReentrant
        isVerified(proof)
    {
        require(isPreSaleActive, "PreSale is not active");
        require(!isPaused, "Paused");
        require(nftAmount > 0, "NFT amount cant be zero");
        require(preSaleCount[msg.sender] + nftAmount <= PRESALE_LIMIT, "PreSale Limit exceeded");
        require(_currentTokenID + nftAmount <= MAX_SUPPLY, "Max Supply exceeded");
        require(cids.length == nftAmount, "Cids-NFTAmount mismatch");
        require(msg.value == nftAmount * NFT_MINTING_PRICE, "Incorrect ETH");

        preSaleCount[msg.sender] += nftAmount;
        for (uint256 i = 0; i < nftAmount;) {
            _mintToken(msg.sender, cids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _mintToken(address to, string calldata cid) internal {
        uint256 tokenId = _currentTokenID;
        _safeMint(to, tokenId);
        if (bytes(cid).length != 0) {
            tokenCids[tokenId] = cid;
        }
        unchecked {
            _currentTokenID = tokenId + 1;
        }
    }
}
