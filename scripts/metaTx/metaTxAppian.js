const {ethers, upgrades} = require("hardhat");

async function deployScript(){
    console.log("Deploying the ERC-721 smart contract for yexle....");
    const appian = await ethers.getContractFactory("contracts/metaTx_Appian/YexleMetaTx.sol:YexleMetaTx");
    const trustedForwarder = "0xC94Fbd1b7B619034A3a73953fBDc888Ee62503e1";
    const deployC = await appian.deploy("https://ipfs.io/ipfs/", trustedForwarder);
    await deployC.deployed();
    console.log("The deployed ERC-721 contract address is => ", deployC.address);
}

deployScript();