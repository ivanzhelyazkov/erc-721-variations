import { ethers } from 'hardhat';
import { expect } from 'chai';

import { BytesLike, solidityKeccak256 } from 'ethers/lib/utils';
import {
  createMerkleTree,
  deployArgs,
  toWei
} from './helpers';
import { NFTBitmap } from '../typechain-types';
import MerkleTree from 'merkletreejs';
import { PromiseOrValue } from '../typechain-types/common';

describe("NFTBitmap", function () {
  let erc721: NFTBitmap;
  let owner, signer, user1, user2;
  let presaleMerkleTreeBitmap: MerkleTree;
  let presaleMerkleTreeRootBitmap: PromiseOrValue<BytesLike>;

  describe("presale mint", async function () {
    beforeEach(async function () {
        [owner, signer, user1, user2] = await ethers.getSigners();
        const presaleNumAndAddressList = [
          { bitmapNumber: 1, address: user1.address },
          { bitmapNumber: 7, address: user2.address },
        ];

        presaleMerkleTreeBitmap = await createMerkleTree(
          presaleNumAndAddressList
        );
        presaleMerkleTreeRootBitmap = presaleMerkleTreeBitmap.getHexRoot();
        erc721 = await deployArgs("NFTBitmap", "TestNFT", "TNFT", toWei('0.05'));
        await erc721.deployed();
    });

    it("eligible users should be able to make a presale mint", async function () {
      const user1BitmapNum = 1;
      const user2BitmapNum = 7;
      const user1Proof = presaleMerkleTreeBitmap.getHexProof(
        solidityKeccak256(["uint256", "address"], [user1BitmapNum, user1.address])
      );
      const user2Proof = presaleMerkleTreeBitmap.getHexProof(
        solidityKeccak256(["uint256", "address"], [user2BitmapNum, user2.address])
      );

      await erc721.setMerkleRoot(presaleMerkleTreeRootBitmap);

      // mint from user 1
      await erc721.connect(user1).presaleMint(user1BitmapNum, user1Proof, {
        value: ethers.utils.parseEther("0.05"),
      });
      expect(await erc721.balanceOf(user1.address)).to.be.equal(1);
      // mint from user 2
      await erc721.connect(user2).presaleMint(user2BitmapNum, user2Proof, {
        value: ethers.utils.parseEther('0.05')
      });
      expect(await erc721.balanceOf(user2.address)).to.be.equal(1);
    });

    it("shouldn\'t be able to mint twice", async function () {
      const bitmapNumber = 1;
      const address = user1.address;
      const proof = presaleMerkleTreeBitmap.getHexProof(
        solidityKeccak256(["uint256", "address"], [bitmapNumber, address])
      );

      await erc721.setMerkleRoot(presaleMerkleTreeRootBitmap);

      await erc721.connect(user1).presaleMint(bitmapNumber, proof, {
        value: ethers.utils.parseEther("0.05"),
      });
      await expect(erc721.connect(user1).presaleMint(bitmapNumber, proof, {
        value: ethers.utils.parseEther("0.05"),
      })).to.be.revertedWithCustomError(erc721, 'MintedAlready');
    });
  });
});