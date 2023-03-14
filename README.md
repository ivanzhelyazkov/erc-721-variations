# ERC-721 Variations

## 1. NFT with whitelisted presale and public sale
- Contract is `NFTBitmap.sol`
- ERC-721 contract with a whitelisted presale, which uses a bitmap to track if an address has claimed his NFT or not and if the address is included in the whitelist
- Big gas savings vs. using an ordinary mapping - about 17k gas on claim for the user and 20k * whitelisted user count for the deployer (if using a mapping to indicate whether an address is included, deployer must pay for each address individually, which is 1 SSTORE - 20k gas per address) 
- Using bitmaps costs only 5k gas per address to store whether the address has claimed - by triggering just 1 bit from true to false (in an uint256 bitmap)
- Additional information about the method here:
https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0

## 2. NFT Staking contract
- Contract is `NFTStaking.sol`
- Accepts NFTs and immediately starts accumulating rewards for users. Rewards are accumulated per second and paid out in ERC-20 tokens, they are set on deployment.
- Contract works with any ERC-721 for staking and ERC-20 token for reward payment
- Users can stake as many NFTs as they want, each NFT increases user's reward linearly.

## 3. Enumerable NFT prime counting
- Contract is `EnumerableNFT.sol`
- Mints enumerable nfts to users and provides a function to which takes in an user's address and returns the count of NFTs ids belonging to that user which are prime numbers


## Setting up the repo
`npm install`   
`npx hardhat test`