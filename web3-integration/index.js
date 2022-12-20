const express = require('express');
const dotEnv = require("dotenv");
const axios = require("axios");
const FormData = require('form-data');
const fileupload = require("express-fileupload");
const integration = require('./services/integration');

const app = express();
// Config env file
dotEnv.config();
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

app.post('/user/create', (req, res) => {
  let {address} = req.body;
  return integration.addUser(address)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
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

app.post('/user/bulk_create', (req, res) => {
  let {addresses} = req.body;
  return integration.addUserBulk(addresses)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
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
  let {land_id, owner, token_ipfs_hash} = req.body;
  return integration.mint(owner, land_id, token_ipfs_hash)
  .then((resp) => {
    if (resp.status) {
      return res.status(200).send({
        status: resp.status,
        transaction_hash: resp.transactionHash
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
}



app.use((req, res) => {
  res.status(404).send({error: `${req.path} not found`});
})

app.use((err, req, res, next) => {
  res.status(500).send({error: err.message});
})

app.listen(3000, () => {
  console.log("App started! http://localhost:3000")
});