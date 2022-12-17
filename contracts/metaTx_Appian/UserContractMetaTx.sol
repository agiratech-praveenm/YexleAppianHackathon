// SPDX-License-Identifier: MIT
/*
/$$      /$$                  /$$                  /$$$$$$                      /$$                    
|  $$   /$$/                 | $$                 /$$__  $$                    |__/                    
 \  $$ /$$//$$$$$$  /$$   /$$| $$  /$$$$$$       | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$  /$$$$$$$ 
  \  $$$$//$$__  $$|  $$ /$$/| $$ /$$__  $$      | $$$$$$$$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$
   \  $$/| $$$$$$$$ \  $$$$/ | $$| $$$$$$$$      | $$__  $$| $$  \ $$| $$  \ $$| $$  /$$$$$$$| $$  \ $$
    | $$ | $$_____/  >$$  $$ | $$| $$_____/      | $$  | $$| $$  | $$| $$  | $$| $$ /$$__  $$| $$  | $$
    | $$ |  $$$$$$$ /$$/\  $$| $$|  $$$$$$$      | $$  | $$| $$$$$$$/| $$$$$$$/| $$|  $$$$$$$| $$  | $$
    |__/  \_______/|__/  \__/|__/ \_______/      |__/  |__/| $$____/ | $$____/ |__/ \_______/|__/  |__/
                                                           | $$      | $$                              
                                                           | $$      | $$                              
                                                           |__/      |__/                                                                                                                                                                   
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserContractMetaTx is ERC2771Context, Ownable{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notL1Address();
    error approverAlreadyExist();
    
    address public trustedForwarder;
    address[] private pushUsers;
    address[] private adminAddresses;
    address private L1Approver;
    
    mapping(address => bool) private isUser;
    mapping(address => bool) private adminAddress;
    mapping(address => bool) private approverAddress;

    struct userBulkData{
        address _ad;
    }

    constructor(address _trustedForwarder)ERC2771Context(_trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    function setTrustedForwarder(address _newForwarder) external onlyOwner{
        trustedForwarder = _newForwarder;
    }

    function versionRecipient() external pure returns(string memory){
        return "1";
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns(address){
        return ERC2771Context._msgSender();
    } 

    function _msgData() internal view override(Context, ERC2771Context) returns(bytes calldata){
        return ERC2771Context._msgData();
    }

    function whitelistApproverL1(address _approverAd) external onlyOwner{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }
    
    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
    */
    function addUser(address _ad) external {
        if(_msgSender() != L1Approver){ revert notL1Address();}
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        isUser[_ad] = true;
        pushUsers.push(_ad);
    }

    /**
        * addUserBulk
        * @param _userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(userBulkData[] memory _userData) external {
        if(_msgSender() != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]._ad] = true;
            pushUsers.push(_userData[i]._ad);
        }
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool){
        if(isUser[_ad]){
            return true;
        }else{
            return false;
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    function L1ApproverAddress() external view returns(address){
        return L1Approver;
    } 
}