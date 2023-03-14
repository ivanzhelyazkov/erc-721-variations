import { keccak256, solidityKeccak256 } from 'ethers/lib/utils';
import { MerkleTree } from 'merkletreejs';
import { BigNumber } from 'ethers';
import { ethers, network } from 'hardhat';


/**
 * Deploy a contract by name without constructor arguments
 */
export async function deploy(contractName) {
  let Contract = await ethers.getContractFactory(contractName);
  return await Contract.deploy();
}

/**
* Deploy a contract by name with constructor arguments
*/
export async function deployArgs(contractName, ...args) {
  let Contract = await ethers.getContractFactory(contractName);
  return await Contract.deploy(...args);
}

/**
 * Return a number with 18 decimals
 * @param {*} amount 
 * @returns 
 */
export function toWei(amount) {
  return ethers.utils.parseEther(amount);
}

export async function createMerkleTree(presaleList) {
  let leafNodes = presaleList.map((obj) =>
    solidityKeccak256(["uint256", "address"], [obj.bitmapNumber, obj.address])
  );
  return new MerkleTree(leafNodes, keccak256, { sortPairs: true });
}

/**
* Increase time in Hardhat Network
*/
export async function increaseTime(time: number) {
  await network.provider.send("evm_increaseTime", [time]);
  await network.provider.send("evm_mine");
}

/**
 * Mine several blocks in network
 * @param {Number} blockCount how many blocks to mine
 */
export async function mineBlocks(blockCount: number) {
    for(let i = 0 ; i < blockCount ; ++i) {
        await network.provider.send("evm_mine");
    }
}