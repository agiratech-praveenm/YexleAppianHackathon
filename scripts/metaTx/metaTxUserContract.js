const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the UserContract...");
    const baseC = await ethers.getContractFactory("contracts/metaTx_Appian/UserContractMetaTx.sol:UserContractMetaTx");
    const trustedForwarder = "0x69015912AA33720b842dCD6aC059Ed623F28d9f7";
    const deployC = await baseC.deploy(trustedForwarder);
    await deployC.deployed();
    console.log("The deployed UserContract address is =>  ", deployC.address);
}

deployScript();
