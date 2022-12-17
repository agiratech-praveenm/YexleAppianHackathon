const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

describe("$$ Testing Yexle Contract $$", function(){
    let contract; 

    before(async function(){
        const [dep,l1, l2, BUYER] = await ethers.getSigners();
        const setup = await ethers.getContractFactory("contracts/YexleAppian.sol:YexleAppian");
        const deployC = await setup.deploy("https://ipfs.io/ipfs/");
        contract = await deployC.connect(dep).attach("0x5D4b403e7a89a86856Ec211a1dA56e9d155047A9");
        console.log("This is the local deployed contract address -> ", contract.address, BUYER.address);
    })

    // it("Adding L1 Approver to the smart contract", async function(){
    //     const [dep,l1, l2] = await ethers.getSigners();
    //     const l1address = "0x71A66921E1429c29C9c234f8d71504C88e503392";
    //     const l1approverCall = await contract.connect(dep).whitelistApproverL1(l1.address)
    //     console.log(l1approverCall);
    // })

    // it("Adding L2 Approver to the smart contract", async function(){
    //     const [dep,l1, l2] = await ethers.getSigners();
    //     const l2address = "0xb9Bc22C3dF733F9bF44da3644e118386195c154A";
    //     const l2ApproverCall = await contract.connect(dep).whitelistApproverL1(l2.address)
    //     console.log(l2ApproverCall);
    // })

    // it("Whitelist the userContract address", async function(){
    //     const [dep,l1, l2] = await ethers.getSigners();
    //     const userContract = "0x2308644314ABdb3319940C07b4a386be7eA6319D";
    //     const userContractCall = await contract.connect(dep).whitelistUserContract(userContract)
    //     console.log(userContractCall);
    // })

    // it("Mint token to the users", async function(){
    //     const [dep,l1, l2] = await ethers.getSigners();
    //     const mintOwner = "0x48228E597fe765015A7a0c3bb7Ee6FAa7D7daade";
    //     const tokenURI = "QmQGDChDEkGaZnyuCgdgMj63Q7NjP5GZKjW9ryfy2hXn9R";
    //     const mintCall = await contract.connect(l1).mint(mintOwner, 2, tokenURI);
    //     console.log(mintCall);
    // })

    // it("Land view request by some user or interested buyer", async function(){
    //     const [dep,l1, l2, BUYER] = await ethers.getSigners();
    //     const interestedBuyer = "0x5Ec39fe3576d857655C5C476AA1e0D30c5F6A0D8";
    //     const landDocumentViewRequestCall = await contract.connect(l1).landDocumentViewRequest(interestedBuyer, 2);
    //     console.log(landDocumentViewRequestCall);
    // })

    it("Land view request by some user or interested buyer", async function(){
        const [dep,l1, l2, BUYER] = await ethers.getSigners();
        const interestedBuyer = "0x5Ec39fe3576d857655C5C476AA1e0D30c5F6A0D8";
        const landDocumentViewRequestCall = await contract.connect(l1).landDocumentViewRequest(interestedBuyer, 2);
        console.log(landDocumentViewRequestCall);
    })

    it("Request land for sale - who ever have passed the ", async function(){
        const [dep,l1, l2, BUYER] = await ethers.getSigners();
        const interestedBuyer = "0x5Ec39fe3576d857655C5C476AA1e0D30c5F6A0D8";
        const landDocumentViewRequestCall = await contract.connect(l1).landDocumentViewRequest(interestedBuyer, 2);
        console.log(landDocumentViewRequestCall);
    })
})