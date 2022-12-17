const {ethers, upgrades} = require("hardhat");

async function deployScript(){
    console.log("Deploying the ERC-721 smart contract for yexle....");
    const appian = await ethers.getContractFactory("contracts/YexleAppian.sol:YexleAppian");
    const deployC = await appian.deploy("https://ipfs.io/ipfs/");
    await deployC.deployed();
    console.log("The deployed ERC-721 contract address is => ", deployC.address);
}

deployScript();