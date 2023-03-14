// SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract EnumerableNFT is ERC721Enumerable {
    uint public constant MAX_SUPPLY = 20;
    uint public currentNftId = 1;
    string public baseTokenURI =
        "ipfs://example-uri/";

    error MintTooBig();

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    /**
     * @dev Public token mint
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint _mintNumber) external virtual {
        // check for max supply
        if(totalSupply() + _mintNumber > MAX_SUPPLY) {
            revert MintTooBig();
        }

        for (uint i = 0; i < _mintNumber; i++) {
            _safeMint(msg.sender, currentNftId);
            currentNftId++;
        }
    }

    /**
     * @notice get count of prime nfts
     */
    function getPrimeNfts(address owner) external view returns (uint) {
        uint balance = balanceOf(owner);
        uint primeCount = 0;
        for(uint i = 0 ; i < balance ; ++i) {
            // get token id
            uint tokenId = tokenOfOwnerByIndex(owner, i);
            if(isPrime(tokenId)) {
                primeCount++;
            }
        }
        return primeCount;
    }

    /**
     * @dev check if a number is prime
     */
    function isPrime(uint256 n) private pure returns (bool) {
        if (n <= 1) {
            return false;
        }
        for (uint256 i = 2; i <= n / 2; i++) {
            if (n % i == 0) {
                return false;
            }
        }
        return true;
    }
}