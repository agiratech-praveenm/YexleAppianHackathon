const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the UserContract...");
    const baseC = await ethers.getContractFactory("contracts/UserContract.sol:UserContract");
    const deployC = await baseC.deploy();
    await deployC.deployed();
    console.log("The deployed UserContract address is =>  ", deployC.address);
}

deployScript();
