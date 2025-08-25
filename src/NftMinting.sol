// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NftMinting is ERC721, ReentrancyGuard, PaymentSplitter, Ownable {
    using Strings for uint256;

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

    function publicSaleMint(uint256 nftAmount, string[] calldata cids) external payable onlyEOA nonReentrant {
        require(isPublicSaleActive, "PublicSale is not active");
        require(!isPaused, "Paused");
        require(nftAmount > 0, "NFT amount cant be zero");
        require(_currentTokenID + nftAmount <= MAX_SUPPLY, "Max Supply exceeded");
        require(cids.length == nftAmount, "Cids-NFTAmount mismatch");
        require(msg.value == nftAmount * NFT_MINTING_PRICE, "Incorrect ETH");

        for (uint256 i = 0; i < nftAmount;) {
            _mintToken(msg.sender, cids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _requireOwnedBySender(uint256 tokenId) internal view {
        require(_exists(tokenId), "Nonexistent Token");
        require(ownerOf(tokenId) == msg.sender, "Owner Mismatch");
        require(ownerOf(tokenId) != address(0), "Token is not owned");
    }

    function setCid(uint256 tokenId, string calldata cid) external {
        _requireOwnedBySender(tokenId);
        tokenCids[tokenId] = cid;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory base = _baseTokenURI;
        string memory cid = tokenCids[tokenId];
        if (bytes(cid).length != 0) {
            return string(abi.encodePacked(base, cid));
        }
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    function totalSupply() external view returns (uint256) {
        return _currentTokenID;
    }

    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - _currentTokenID;
    }

    function withdrawEther() external onlyOwner {
        require(address(this).balance > 0, "Contract has zero balance");
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function releaseAll() external {
        for (uint256 i = 0; i < _teamMembers.length;) {
            release(payable(_teamMembers[i]));
            unchecked {
                ++i;
            }
        }
    }
}