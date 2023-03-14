import { ethers } from 'hardhat';
import { expect } from 'chai';

import {
  deployArgs
} from './helpers';
import { EnumerableNFT } from '../typechain-types';

describe("EnumerableNFT", function () {
  let erc721: EnumerableNFT;
  let owner, signer, user1, user2;

  describe("Checking for prime numbers", async function () {
    beforeEach(async function () {
        [owner, signer, user1, user2] = await ethers.getSigners();
        
        erc721 = await deployArgs('EnumerableNFT', 'Test', 'Test');
        await erc721.deployed();
    });

    it("user should be able to mint", async function () {
      await erc721.connect(user1).publicMint(5);
      let bal = await erc721.balanceOf(user1.address);
      expect(bal).to.be.eq(5);
    });

    it("should be able to check prime nft count", async function () {
      await erc721.connect(owner).publicMint(5); // owner owns nfts 1 - 5
      await erc721.connect(user1).publicMint(5); // user 1 owns 6 - 10
      await erc721.connect(user2).publicMint(5); // user 2 owns 11 - 15
      let ownerCount = await erc721.getPrimeNfts(owner.address);
      let user1Count = await erc721.getPrimeNfts(user1.address);
      let user2Count = await erc721.getPrimeNfts(user2.address);
      expect(ownerCount).to.be.eq(3); // 3 prime nums from 1 - 5
      expect(user1Count).to.be.eq(1); // 1 prime num from 6 - 10
      expect(user2Count).to.be.eq(2); // 2 prime nums from 11 - 15
      console.log('owner count:', ownerCount);
      console.log('user 1 count:', user1Count);
      console.log('user 2 count:', user2Count);
    });
  });
});