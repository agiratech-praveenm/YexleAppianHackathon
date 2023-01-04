const {ethers} = require("hardhat");

async function deployScript(){
    
    const appian = await ethers.getContractFactory("contracts/Agiracoin.sol:Agiracoin");
    const deployC = await appian.deploy();
    await deployC.deployed();
    console.log("The deployed agiracoin contract address is => ", deployC.address);
}

deployScript();