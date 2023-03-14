// SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";


/**
 * @title ERC-721 Presale and Public sale contract
 * @notice Allows for presale and public minting of ERC-721 tokens
 * @notice Presale minting is enforced using a whitelist stored in a merkle tree
 * @notice Addresses get verified against the whitelist using merkle proofs
*/
contract NFTBitmap is
    ERC721,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    uint public constant MAX_SUPPLY = 50;
    uint96 public constant ROYALTY_FEE = 250;

    uint public immutable price;
    uint[4] bitmapArr = [type(uint).max, type(uint).max, type(uint).max, type(uint).max];

    string public baseTokenURI =
        "ipfs://example-uri/";

    // current minted token index
    uint private supplyIndex;
    // root of the merkle tree for presale address validation
    bytes32 public merkleRoot;

    // Errors
    error InvalidPrice();
    error MintedAlready();
    error MintTooBig();
    error InvalidMerkleProof();
    error IncorrectBitmapNumber();

    /**
     * @notice constructor
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _price start price
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint _price
    ) ERC721(_name, _symbol) {
        _setDefaultRoyalty(msg.sender, ROYALTY_FEE);
        price = _price;
    }

    /**
     * @dev See {IERC721-approve}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(
        address operator,
        uint tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Base uri view
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }


    /**
     * @dev Set the merkle root
     * @param _merkleRoot New merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Public token mint
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint _mintNumber) external payable virtual {
        // check for price
        if(msg.value != price * _mintNumber) {
            revert InvalidPrice();
        }
        // check for max supply
        if(totalSupply() + _mintNumber > MAX_SUPPLY) {
            revert MintTooBig();
        }

        for (uint i = 0; i < _mintNumber; i++) {
            _safeMint(msg.sender, supplyIndex);
            supplyIndex++;
        }
    }

    /**
     * @dev Allows for presale minting of tokens for allowlisted addresses uising a bitmap
     * @param _bitmapNumber Bitmap number to verify corresponding to the msg.sender address
     * @param _merkleProof Merkle proof for the address
     */
    function presaleMint(
        uint _bitmapNumber,
        bytes32[] calldata _merkleProof
    ) external payable {
        if(totalSupply() > MAX_SUPPLY) {
            revert MintTooBig();
        }
        if(msg.value != price) {
            revert InvalidPrice();
        }
        if(_bitmapNumber >= MAX_SUPPLY) {
            revert IncorrectBitmapNumber();
        }
        bool validProof = verifyMerkleProof(msg.sender, _bitmapNumber, _merkleProof);
        if(!validProof) {
            revert InvalidMerkleProof();
        }

        // find the bitmap array index
        uint bitmapArrIdx = _bitmapNumber / 256;
        // find the bit in the bitmap
        uint offsetWithinLocalBitmap = _bitmapNumber % 256;

        uint bitmap = bitmapArr[bitmapArrIdx];
        // get the stored bit
        uint storedBit = (bitmap >> offsetWithinLocalBitmap) &
            uint(1);
        // check if the bit is 0 - if so, address has minted
        if(storedBit == 0) {
            revert MintedAlready();
        }
        // set the bit to 0
        bitmapArr[bitmapArrIdx] = bitmap & ~(uint(1) << offsetWithinLocalBitmap);

        _safeMint(msg.sender, supplyIndex);
        supplyIndex++;
    }

    /**
     * @dev Verify that an address is eligible for presale minting using a bitmap
     * @param _address Address to verify
     * @param _merkleProof Merkle proof for the address
     */
    function verifyMerkleProof(
        address _address,
        uint _bitmapNumber,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_bitmapNumber, _address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Returns the total supply of tokens
     */
    function totalSupply() public view returns (uint) {
        return supplyIndex;
    }

    /**
     * @dev Allow contract owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}