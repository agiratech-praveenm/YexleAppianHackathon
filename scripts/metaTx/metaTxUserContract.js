const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the UserContract...");
    const baseC = await ethers.getContractFactory("contracts/metaTx_Appian/UserContractMetaTx.sol:UserContractMetaTx");
    const trustedForwarder = "0xC94Fbd1b7B619034A3a73953fBDc888Ee62503e1";
    const deployC = await baseC.deploy(trustedForwarder);
    await deployC.deployed();
    console.log("The deployed UserContract address is =>  ", deployC.address);
}

deployScript();
