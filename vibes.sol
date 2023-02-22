// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vibes is ERC1155, Ownable {
    address private _feeWallet;
    mapping (uint256 => uint256) private _totalSupply;
    uint256 public _mintFee = 1 ether;
    mapping (uint256 => bool) private _tokenExists;
    string private _baseURI;

    constructor(address feeWallet, string memory baseURI) ERC1155("Vibes") {
        _feeWallet = feeWallet;
        _baseURI = baseURI;
    }

    function setFeeWallet(address feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Invalid fee wallet address");
        _feeWallet = feeWallet;
    }

    function mint(address to, uint256 id, uint256 amount) external payable {
        require(_exists(id), "ERC1155: Cannot Mint a Token Id that doesn't exist");
        require(to != address(msg.sender), "Invalid recipient address");
        require(msg.value == _mintFee * amount, "Insufficient mint fee");

        _mint(to, id, amount, "[]");
        _totalSupply[id] += amount;

        payable(_feeWallet).transfer(msg.value);
    }

    function mintToOwner(uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(msg.sender, id, amount, data);
        _totalSupply[id] += amount;
        if (!_tokenExists[id]) {
            _tokenExists[id] = true;
        }
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function setMintFee(uint256 mintFee) public onlyOwner {
        _mintFee = mintFee;
    }

    function _exists(uint256 tokenId) public view returns (bool) {
        return _tokenExists[tokenId];
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function _internalBaseURI() internal view returns (string memory) {
        return _baseURI;
    }
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC1155Metadata: URI query for nonexistent token");

        string memory baseURI_ = _internalBaseURI();

        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, uint2str(tokenId), ".json")) : "";
    }
}
