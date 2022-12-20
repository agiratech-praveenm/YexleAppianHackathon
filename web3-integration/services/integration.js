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
const addUser = async (addressDetails) => {
  if (isAddress(addressDetails._l1) && isAddress(addressDetails._ad)) {
    let { userSigner, provider } = initiateUserContract();
    return userSigner.addUser(addressDetails, {
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

const addUserBulk = async (l1, addresses) => {
  let { userSigner, provider } = initiateUserContract();
  return userSigner.addUserBulk1(l1, addresses, {
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

const mint = async (_l1, _to, land_id, token_ipfs_hash) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.mint(_l1, _to, land_id, token_ipfs_hash, {
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

const landDocumentViewRequestApprove = async (_l1, _requestor, land_id, status) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.landDocumentViewRequestApprove(_l1, _requestor, land_id, status, {
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

const viewDocumentByRequesters = async (_requestor, land_id) => {
  let {regContract} = initiateRegistrationContract();
   let land  = await regContract.viewDocumentByRequesters(_requestor, land_id);
   return land;
}

const requestLandForSale = async (_requestor, land_id) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.requestLandForSale(_requestor, land_id, {
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

const ownerDecisionforRaisedRequest = async (owner, _requestor, land_id, status) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.ownerDecisionforRaisedRequest(owner, _requestor, land_id, status, {
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

const registrationForLandByBuyer = async (_requestor, land_id, docUri) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.registrationForLandByBuyer(_requestor, land_id, docUri, {
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

const approveByL1 = async (_l1, data) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.approveByL1(_l1, data, {
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

const approveByL2 = async (_l2, data) => {
  let {regSigner, provider} = initiateRegistrationContract();
  return regSigner.approveByL2(_l2, data, {
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
  registrationForLandByBuyer,
  approveByL1,
  approveByL2
}