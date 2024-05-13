// SPDX-License-Identifier: MIT
// Address: 0x7c9F38aa384f92AD63e0849Cc5CBF5c8CEda5EDc
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IExternalERC721 is IERC721 {}

contract GetCookin is Ownable, ReentrancyGuard {
    // Reference to the external ERC-721 contract
    IExternalERC721 public externalERC721;

    // Tracks whether a user has bookmarked a specific token ID
    mapping(uint256 => mapping(address => bool)) public hasBookmarkedToken;

    // Tracks the number of likes for each token ID
    mapping(uint256 => uint256) public likes;

    // Tracks the total amount tipped to each address
    mapping(address => mapping(address => uint256)) public totalTips;

    // Tracks the total amount tipped to each token ID for each token type
    mapping(uint256 => mapping(address => uint256)) public totalTipsByTokenId;

    // Mapping from token ID to token type to an array of tipping details
    mapping(uint256 => mapping(address => TipDetail[])) public tipsByTokenId;

    // Tracks whether a user has liked a specific token ID
    mapping(uint256 => mapping(address => bool)) public hasLikedToken;

    // Mapping of whitelisted tokens and array for easy retrieval
    mapping(address => bool) public whitelistedTokens;
    address[] public whitelistedTokenList;

    // Define a struct to hold tipping details
    struct TipDetail {
        address tipper;
        uint256 amount;
}

    event Like(uint256 indexed tokenId, address indexed liker);
    event Unlike(uint256 indexed tokenId, address indexed unliker);
    event Tip(address indexed from, address indexed to, address indexed token, uint256 amount, uint256 tokenId);
    event TokenWhitelisted(address indexed token);
    event TokenRemovedFromWhitelist(address indexed token);
    event Bookmark(uint256 indexed tokenId, address indexed bookmarker);
    event Unbookmark(uint256 indexed tokenId, address indexed bookmarker);

    // Constructor to set the external ERC-721 contract address and ownership
    constructor(address _externalERC721Address, address initialOwner) Ownable(initialOwner) {
        require(_externalERC721Address != address(0), "Invalid ERC-721 address");
        require(initialOwner != address(0), "Invalid owner address");
        externalERC721 = IExternalERC721(_externalERC721Address);
    }

    // Function to toggle the like status for a token ID
    function like(uint256 tokenId) external {
        require(externalERC721.ownerOf(tokenId) != address(0), "Token does not exist");

        if (hasLikedToken[tokenId][msg.sender]) {
            // User has already liked this token, so we remove the like
            likes[tokenId] -= 1;
            hasLikedToken[tokenId][msg.sender] = false;
            emit Unlike(tokenId, msg.sender);
        } else {
            // User has not yet liked this token, so we add a like
            likes[tokenId] += 1;
            hasLikedToken[tokenId][msg.sender] = true;
            emit Like(tokenId, msg.sender);
        }
    }

    // Function to tip the current owner of a token with a specified whitelisted ERC-20 token
    function tip(uint256 tokenId, address tokenAddress, uint256 amount) external nonReentrant {
        require(whitelistedTokens[tokenAddress], "Token not whitelisted");
        require(amount > 0, "Invalid amount");

        address owner = externalERC721.ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");

        require(IERC20(tokenAddress).transferFrom(msg.sender, owner, amount), "Transfer failed");

        // Append the new tip detail to the array for the given token ID and token type
        tipsByTokenId[tokenId][tokenAddress].push(TipDetail({
            tipper: msg.sender,
            amount: amount
        }));

        emit Tip(msg.sender, owner, tokenAddress, amount, tokenId); // Include tokenId in the event
    }

    // Function to check whether a user has already liked a given token ID
    function hasLiked(uint256 tokenId, address user) external view returns (bool) {
        return hasLikedToken[tokenId][user];
    }

    // Helper function to retrieve the total tips received by a particular address in a specific token
    function getTotalTips(address recipient, address tokenAddress) external view returns (uint256) {
        return totalTips[recipient][tokenAddress];
    }

    // Helper function to retrieve the total tips received by a particular token ID in a specific token
    function getTotalTipsByTokenId(uint256 tokenId, address tokenAddress) external view returns (uint256) {
        return totalTipsByTokenId[tokenId][tokenAddress];
    }

        // Function to retrieve all tips for a specific token ID and token type
    function getTipsForToken(uint256 tokenId, address tokenAddress) external view returns (TipDetail[] memory) {
        return tipsByTokenId[tokenId][tokenAddress];
    }

    // Function to toggle the bookmark status for a token ID
    function bookmark(uint256 tokenId) external {
        require(externalERC721.ownerOf(tokenId) != address(0), "Token does not exist");

        if (hasBookmarkedToken[tokenId][msg.sender]) {
            // User has already bookmarked this token, so we remove the bookmark
            hasBookmarkedToken[tokenId][msg.sender] = false;
            emit Unbookmark(tokenId, msg.sender);
        } else {
            // User has not yet bookmarked this token, so we add a bookmark
            hasBookmarkedToken[tokenId][msg.sender] = true;
            emit Bookmark(tokenId, msg.sender);
        }
    }

    // Function to check whether a user has already bookmarked a given token ID
    function hasBookmarked(uint256 tokenId, address user) external view returns (bool) {
        return hasBookmarkedToken[tokenId][user];
    }

    // Adds a token to the whitelist
    function whitelistToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(!whitelistedTokens[tokenAddress], "Token already whitelisted");

        whitelistedTokens[tokenAddress] = true;
        whitelistedTokenList.push(tokenAddress);
        emit TokenWhitelisted(tokenAddress);
    }

    // Removes a token from the whitelist
    function removeTokenFromWhitelist(address tokenAddress) external onlyOwner {
        require(whitelistedTokens[tokenAddress], "Token not whitelisted");

        whitelistedTokens[tokenAddress] = false;
        emit TokenRemovedFromWhitelist(tokenAddress);

        // Remove the address from the list
        for (uint256 i = 0; i < whitelistedTokenList.length; i++) {
            if (whitelistedTokenList[i] == tokenAddress) {
                whitelistedTokenList[i] = whitelistedTokenList[whitelistedTokenList.length - 1];
                whitelistedTokenList.pop();
                break;
            }
        }
    }

    // Function to get all whitelisted tokens
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokenList;
    }
}
