const express = require('express');
const cors = require('cors');
require("dotenv").config();
const axios = require("axios");
const FormData = require('form-data');
const fileupload = require("express-fileupload");
const integration = require('./services/integration');

const app = express();
app.use(cors());
// // Config env file
// dotEnv.config();
app.use(express.json());
app.use(fileupload());
app.use(function(req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Access-Control-Allow-Origin, Content-Type, Accept, Cache-Control');
    res.setHeader('Access-Control-Allow-Credentials', true);
    next();
});

app.get("/generate_wallet", async (req, res) => { 
  res.send(integration.createAddress());
})

app.post('/user/whitelist_l1', (req, res) => {
  return integration.whitelistUserApproverL1(req.body.l1)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      message: 'User creation failed',
      error: err.message
    })
  })
})

app.post('/user/create', (req, res) => {
  return integration.addUser(req.body)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      message: 'User creation failed',
      error: err.message
    })
  })
})

app.post('/user/bulk_create', (req, res) => {
  return integration.addUserBulk(req.body._l1, req.body.addresses)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Land creation failed',
      error: err.message
    })
  })
})

app.post('/whitelist_l1_approver', (req, res) => {
  return integration.whitelistApproverL1(req.body.l1)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      message: 'User creation failed',
      error: err.message
    })
  })
})

app.post('/whitelist_l2_approver', (req, res) => {
  return integration.whitelistApproverL2(req.body.l2)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      message: 'User creation failed',
      error: err.message
    })
  })
})

app.post('/pin_file', (req, res, next) => {
  try {
    const url = "https://api.pinata.cloud/pinning/pinFileToIPFS";
    let formData = new FormData();
    formData.append("file", req.files.file.data, {filepath: "yexle-appian"});

    axios
      .post(url, formData, {
        maxContentLength: -1,
        headers: {
          "Content-Type": `multipart/form-data; boundary=${formData._boundary}`,
          pinata_api_key: process.env.PINATA_API_KEY,
          pinata_secret_api_key: process.env.PINATA_API_SECRET,
          path: "yexle-appian",
        },
      })
      .then((data) => {
        return res.send({
          message: "Upload image to ipfs.",
          cid: data.data
        })
      })
      .catch((err) => {
        res.status(400).send({error: err.message});
      });
  } catch (error) {
    next(error);
  }
});

app.post('/pin_json', (req, res, next) => {
  try {
    const config = {
      method: 'post',
      url: 'https://api.pinata.cloud/pinning/pinJSONToIPFS',
      headers: { 
        'Content-Type': 'application/json',
        pinata_api_key: process.env.PINATA_API_KEY,
        pinata_secret_api_key: process.env.PINATA_API_SECRET,
        path: "yexle-appian",
      },
      data : JSON.stringify(req.body)
    };

    axios(config)
    .then((data) => {
      return res.send({
        message: "Pin json to ipfs.",
        cid: data.data
      })
    })
    .catch((err) => {
      res.status(400).send({error: err.message});
    });
  } catch (error) {
    next(error);
  }
});

app.post('/mint_land', (req, res) => {
  let {_l1, _to, land_id, token_ipfs_hash} = req.body;
  return integration.mint(_l1, _to, land_id, token_ipfs_hash)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Land creation failed',
      error: err.message
    })
  })
})

app.post('/approve_view_request', (req, res) => {
  let {_l1, _requestor, land_id, status} = req.body;
  return integration.landDocumentViewRequestApprove(_l1, _requestor, land_id, status)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.post('/view_land', (req, res) => {
  let {_requestor, land_id} = req.body;
  return integration.viewDocumentByRequesters(_requestor, land_id)
  .then((resp) => {
    if (resp) {
      return res.status(200).send({
        status: 1,
        uri: resp
      })
    } else {
      return res.status(400).send({
        status: 0,
        transaction_hash: "Failed to load land"
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to load land details',
      error: err.message
    })
  })
})

app.patch('/update_land/:land_id', (req, res) => {
  let {token_ipfs_hash, owner} = req.body;
  return integration.setTokenURI(req.params.land_id, token_ipfs_hash, owner)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Land creation failed',
      error: err.message
    })
  })
})

app.post('/request_for_land_sale', (req, res) => {
  let {_requestor, land_id} = req.body;
  return integration.requestLandForSale(_requestor, land_id)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.post('/accept_land_sale_request', (req, res) => {
  let {owner, _requestor, land_id, status} = req.body;
  return integration.ownerDecisionforRaisedRequest(owner, _requestor, land_id, status)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.post('/registration', (req, res) => {
  let {_requestor, land_id, docUri} = req.body;
  return integration.registrationForLandByBuyer(_requestor, land_id, docUri)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.post('/approve_by_l1', (req, res) => {
  let {_l1, data} = req.body;
  return integration.approveByL1(_l1, data)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.post('/approve_by_l2', (req, res) => {
  let {_l2, data, owner} = req.body;
  return integration.approveByL2(_l2, data, owner)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash,
        transaction: resp
      })
    } else {
      return res.status(400).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
      })
    }
  })
  .catch(err => {
    return res.status(400).send({
      message: 'Failed to approve land view request',
      error: err.message
    })
  })
})

app.get('/user/l1_approver', (req, res) => {
  return integration.L1ApproverAddress()
  .then((resp) => {
    return res.status(200).send({
      l1_approver: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/user/:address', (req, res) => {
  return integration.verifyUser(req.params.address)
  .then((resp) => {
    return res.status(200).send({
      status: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/users', (req, res) => {
  return integration.getAllUserAddress()
  .then((resp) => {
    return res.status(200).send({
      users: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/users/count', (req, res) => {
  return integration.UserCounts()
  .then((resp) => {
    return res.status(200).send({
      users_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/metadata_uri', (req, res) => {
  return integration.metadataUri()
  .then((resp) => {
    return res.status(200).send({
      uri: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/owner/:land_id', (req, res) => {
  return integration.ownerOf(req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      owner: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/requester/:land_id/:viewer', (req, res) => {
  return integration.viewDocumentByRequesters(req.params.viewer, req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      uri: resp
    })
  })
  .catch(err => {
    return res.status(400).send({
      error: err.reason || err.message
    })
  })
})

app.get('/land/requester_status/:land_id/:viewer', (req, res) => {
  return integration.LandRequesterStatus(req.params.viewer, req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      status: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/requesters_count/:land_id', (req, res) => {
  return integration.noOfRequestersInfoToViewDoc(req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      requesters_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/requesters/:land_id', (req, res) => {
  return integration.allRequesterAddressForViewDocument(req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      requesters: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/:land_id/:viewer', (req, res) => {
  return integration.viewDocumentByOwnerOrLevelApprovers(req.params.viewer, req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      uri: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/l1_approver', (req, res) => {
  return integration.L1Approver()
  .then((resp) => {
    return res.status(200).send({
      l1_approver: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/l2_approver', (req, res) => {
  return integration.L2Approver()
  .then((resp) => {
    return res.status(200).send({
      l2_approver: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/l1_approval_count', (req, res) => {
  return integration.L1ApprovalCounts()
  .then((resp) => {
    return res.status(200).send({
      l1_approval_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/l2_approval_count', (req, res) => {
  return integration.L2ApprovalCounts()
  .then((resp) => {
    return res.status(200).send({
      l2_approval_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/count', (req, res) => {
  return integration.LandCounts()
  .then((resp) => {
    return res.status(200).send({
      lands_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/registration/status/:land_id', (req, res) => {
  return integration.LandRegistrationStatus(req.params.land_id)
  .then((resp) => {
    return res.status(200).send({
      status: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/land/registrations_count', (req, res) => {
  return integration.completedRegistrations()
  .then((resp) => {
    return res.status(200).send({
      registrations_count: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.get('/lands/:owner', (req, res) => {
  return integration.returnAllUriForLandOwner(req.params.owner)
  .then((resp) => {
    return res.status(200).send({
      lands: resp
    })
  })
  .catch(err => {
    console.log(err)
    return res.status(400).send({
      error: err.message
    })
  })
})

app.use((req, res) => {
  res.status(404).send({error: `${req.path} not found`});
})

app.use((err, req, res, next) => {
  res.status(500).send({error: err.message});
})

app.listen(3000, () => {
  console.log("App started! http://localhost:3000")
});