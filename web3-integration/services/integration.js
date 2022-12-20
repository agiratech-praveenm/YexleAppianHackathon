const ethers = require('ethers');
const userABI = require('./abi/user.json');
const regABI = require('./abi/registration.json');

const PINATA_API_KEY = process.env.PINATA_API_KEY;
const PINATA_API_SECRET = process.env.PINATA_API_SECRET;
const WEB3_PROVIDER = process.env.WEB3_PROVIDER;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const USER_CONTRACT = process.env.USER_CONTRACT;
const REG_CONTRACT = process.env.REG_CONTRACT;

const isAddress = function(address) {
  return ethers.utils.isAddress(address)
}

// contracts initiation
const initiateUserContract = function() {
  const provider = new ethers.providers.JsonRpcProvider(WEB3_PROVIDER);

  const userContract = new ethers.Contract(
    USER_CONTRACT,
    userABI,
    provider
  );

  let wallet = new ethers.Wallet(PRIVATE_KEY);
  let walletSigner = wallet.connect(provider);
  const userSigner = userContract.connect(walletSigner);
  return {userContract, userSigner, provider};
}

const initiateRegistrationContract = function() {
  const provider = new ethers.providers.JsonRpcProvider(WEB3_PROVIDER);

  const regContract = new ethers.Contract(
    REG_CONTRACT,
    regABI,
    provider
  );

  let wallet = new ethers.Wallet(PRIVATE_KEY);
  let walletSigner = wallet.connect(provider);
  const regSigner = regContract.connect(walletSigner);
  return {regContract, regSigner, provider};
}

const createAddress = function() {
  const wallet = ethers.Wallet.createRandom()
  return {
    address: wallet.address,
    private_key: wallet.privateKey,
    phrase: wallet.mnemonic.phrase
  }
}

// write actions with the flow
const addUser = async (address) => {
  if (isAddress(address)) {
    let { userSigner, provider } = initiateUserContract();
    return userSigner.addUser(address, {
      gasLimit: ethers.utils.hexlify(1000000),
    })
    .then(transaction => {
      return provider.waitForTransaction(transaction.hash);
    })
    .then(receipt => {
      return receipt;
    })
    .catch(err => {return err;})
  } else {
    return new Error('Invalid address')
  }
}

const addUserBulk = async (addresses) => {
  let { userSigner, provider } = initiateUserContract();
  return userSigner.addUserBulk(addresses, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

const mint = async (to, tokenId, tokenUri) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.mint(to, tokenId, tokenUri, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

const landDocumentViewRequestApprove = async (requestor, tokenId, status) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.landDocumentViewRequestApprove(requestor, tokenId, status, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

const viewDocumentByRequesters = async (address, tokenId) => {
  let {regContract} = initiateRegistrationContract();
   let land  = await regContract.viewDocumentByRequesters(address, tokenId);
   return land;
}

const requestLandForSale = async (tokenId) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.requestLandForSale(tokenId, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

const ownerDecisionforRaisedRequest = async (requestor, tokenId, status) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.ownerDecisionforRaisedRequest(requestor, tokenId, status, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

const registrationForLandByBuyer = async (tokenId, docUri) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.registrationForLandByBuyer(tokenId, docUri, {
    gasLimit: ethers.utils.hexlify(1000000),
  })
  .then(transaction => {
    return provider.waitForTransaction(transaction.hash);
  })
  .then(receipt => {
    return receipt;
  })
  .catch(err => {return err;})
}

module.exports = {
  createAddress,
  addUser,
  addUserBulk,
  mint,
  landDocumentViewRequestApprove,
  viewDocumentByRequesters,
  requestLandForSale,
  ownerDecisionforRaisedRequest,
  registrationForLandByBuyer
}