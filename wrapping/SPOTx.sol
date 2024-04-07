
pragma solidity ^0.8.0;

import "./Wrapped404.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract SPOTx is ERC165, Wrapped404 {
    string public baseTokenURI;
    uint256 public royaltyAmount;
    address public royaltyReceiver;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bool private _tradingEnabled = false;
    mapping(address => bool) private _isWhiteListed;

    constructor(
        address _owner,
        address _wrappingContract
    ) Wrapped404("SPOTx", "SPOTx", 18, 610, _wrappingContract, _owner) {
        baseTokenURI = "ipfs://QmQobnz1fpDZR5cmhwonK2KF3VJKtTPHv1tG5NVoVyYTdi/";
        royaltyReceiver = 0x32bD2811Fb91BC46756232A0B8c6b2902D7d8763;
        royaltyAmount = 750; // Start at 7.5%
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI, Strings.toString(id));
    }

    // ROYALTIES

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 amount) {
        return (royaltyReceiver, ((_salePrice * royaltyAmount) / 10000));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    // ADMIN

    function setRoyaltyAmount(uint256 _royaltyAmount) public onlyOwner {
        royaltyAmount = _royaltyAmount;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) public onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseTokenURI = _baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        bool isAllowedTransfer = _tradingEnabled ||
            from == owner ||
            to == owner ||
            _isWhiteListed[from] ||
            _isWhiteListed[to];

        if (!isAllowedTransfer) {
            revert("Trading is not enabled or address not whitelisted");
        }
    }

    function enableTrading() public onlyOwner {
        require(!_tradingEnabled, "Trading is already enabled");
        _tradingEnabled = true;
    }

    function whitelistAddress(
        address _address,
        bool isWhitelisted
    ) public onlyOwner {
        _isWhiteListed[_address] = isWhitelisted;
    }
}