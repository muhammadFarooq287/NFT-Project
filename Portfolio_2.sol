// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
*@title NFT Compliance Contract
*@author Muhammad Farooq
*@dev This Contract wcan be used to Perform admin,
*       WhiteListed User and Public USer Minting with a Specific limit  of minting for everyone.
*
*/

contract Portfolio is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{

/**
*@dev Errors will be shown when admin, whiteListed User or Public User minting limit is completed
*       Or When Public sale is Inactive.
*
*/
    error adminMintingLimitReached();
    error whiteListedMintingLimitReached();
    error publicMintingLimitReached();
    error publicSaleIsNotActive();

    uint public totalMintingLimit;
    uint private adminMintingLimit;
    uint public adminMints;
    uint private whiteListedMintingLimit;
    uint public whiteListedMints;
    uint public publicMints;
    bool public publicSaleActive;

    mapping(address=>uint) private nftCount;
    mapping(address=>bool) private whiteListedAddresses;
    mapping(address=>bool) private adminAddresses;

    modifier isAdmin(address _address)
    {
        require(adminAddresses[_address] == true, "Not an Admin");
        _;
    }

    modifier notAdmin(address _address)
    {
        require(adminAddresses[_address] == false, "Already an Admin");
        _;
    }

    modifier isWhiteListed(address _address)
    {
        require(whiteListedAddresses[_address] == true, "Not a WhiteListed User");
        _;
    }

    modifier notWhiteListed(address _address)
    {
        require(whiteListedAddresses[_address] == false, "Already a WhiteListed User");
        _;
    }

    modifier nftRequirementCompleted(
        address _owner)
    {
        require(nftCount[_owner] < 5, "Already minted 5 NFTs.");
        _;
    }

    modifier totalMintingNotReached()
    {
        require(totalMintingLimit != (publicMints+adminMints+whiteListedMints),"Total Minting Limit Reached");
        _;
    }

    constructor() ERC721("Portfolio", "PTF") {}


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

/*
*@dev This function is only for admins selected by Owner of Contract.
*@requirement Sender shoud be Admin. Sender should not have already owned 5 NFTs.
*        Total Minting Limit is not Reached.
*@param Adress of Owner, Token ID, URI
*/

    function adminMint(address to, uint256 tokenId, string memory uri)
        public
        isAdmin(msg.sender)
        nftRequirementCompleted(to)
        totalMintingNotReached
    {
        if(adminMints<adminMintingLimit)
        {
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            nftCount[to] += 1;
            adminMints += 1;
        }
        else
        {
            revert adminMintingLimitReached();
        }
    }

/*
*@dev This function is only for WhiteListed USers selected by Admins of Contract.
*@requirement Sender shoud be WhiteListed User. Sender should not have already owned 5 NFTs.
*        Total Minting Limit is not Reached.
*@param Adress of Owner, Token ID, URI
*/


    function whiteListUserMint(address to, uint256 tokenId, string memory uri)
        public
        isWhiteListed(msg.sender)
        nftRequirementCompleted(to)
        totalMintingNotReached
    {
        if(whiteListedMints<whiteListedMintingLimit)
        {
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            nftCount[to] += 1;
            whiteListedMints +=1;
        }
        else
        {
            revert whiteListedMintingLimitReached();
        }
    }

/*
*@dev This function is for WhiteListed and Public Users selected by Admin of Contract.
*@requirement Sender shoud be whiteListed User or Public User. Sender should not have already owned 5 NFTs.
*        Total Minting Limit is not Reached. Pubic Sale Should Be Active.
*@param Adress of Owner, Token ID, URI
*/

    function publicUserMint(address to, uint256 tokenId, string memory uri)
        public
        notAdmin(msg.sender)
        nftRequirementCompleted(to)
        totalMintingNotReached
    {
        if(publicSaleActive)
        {
            if(publicMints<(totalMintingLimit-adminMintingLimit-whiteListedMintingLimit))
            {
                _safeMint(to, tokenId);
                _setTokenURI(tokenId, uri);
                nftCount[to] += 1;
                publicMints += 1;                
            }
            else
            {
                revert publicMintingLimitReached();
            }
        }
        else
        {
            revert publicSaleIsNotActive();
        }
        
    }

/*
*@dev This function is to add admin address.
*@requirement Sender shoud be owner. New Address should not be an admin.
*@param Adress of new Admin
*/


    function addAdminAddress(
        address _newAddress)
        public
        onlyOwner
        notAdmin(_newAddress)
    {
        adminAddresses[_newAddress] = true;
    }

/*
*@dev This function is to remove admin address.
*@requirement Sender shoud be owner.Old Address should be Admin
*@param Adress of Admin
*/

    function removeAdminAddress(
        address _oldAddress)
        public
        onlyOwner
        isAdmin(_oldAddress)
    {
        adminAddresses[_oldAddress] = false;
    }

/*
*@dev This function is to add whitelisted address.
*@requirement Sender shoud be admin.Old Address should not be whitelisted User
*@param Adress of new whitelisted user
*/

    function addWhiteListedAddress(
        address _newAddress)
        public
        isAdmin(msg.sender)
        notWhiteListed(_newAddress)
    {
        whiteListedAddresses[_newAddress] = true;
    }

/*
*@dev This function is to remove whiteListed address.
*@requirement Sender shoud be Admin.Old Address should be WhiteListed User.
*@param Adress of WhiteListed User
*/

    function removeWhiteListedAddress(
        address _oldAddress)
        public
        isAdmin(msg.sender)
        isWhiteListed(_oldAddress)
    {
        whiteListedAddresses[_oldAddress] = false;
    }

/*
*@dev This function is to set Total Minting Limit
*@requirement Sender shoud be owner.
*@param total minting Limit.
*/

    function setTotalMintingLimit(
        uint _totalMintingLimit)
        public
        onlyOwner
    {
        totalMintingLimit = _totalMintingLimit; 
    }

/*
*@dev This function is to set Admin Minting Limit
*@requirement Sender shoud be owner.
*@param Admin Minting Limit
*/

    function setAdminMintingLimit(
        uint _adminMintingLimit)
        public
        onlyOwner
    {
        adminMintingLimit = _adminMintingLimit; 
    }

/*
*@dev This function is to set WhiteListed User Minting Limit
*@requirement Sender shoud be Admin.
*@param WhiteListed Minting Limit
*/

    function setWhiteListedMintingLimit(
        uint _whiteListedMintingLimit)
        public
        isAdmin(msg.sender)
    {
        whiteListedMintingLimit = _whiteListedMintingLimit; 
    }

/*
*@dev This function is to activate Public Sale
*@requirement Sender shoud be admin
*
*/

    function activatePublicSale()
        public
        isAdmin(msg.sender)
    {
        publicSaleActive = true; 
    }

/*
*@dev This function is to deactivate Public Sale
*@requirement Sender shoud be admin
*
*/

    function UnActivatePublicSale()
        public
        isAdmin(msg.sender)
    {
        publicSaleActive = false; 
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
