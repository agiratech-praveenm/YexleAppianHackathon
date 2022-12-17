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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './UserContract.sol';

contract YexleAppian is ERC721Burnable, Ownable {
    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error URIQueryForNonexistentToken();    
    error zeroAddressNotSupported();
    error approverAlreadyExist();
    error NotAnAdmin();
    error NotOwnerOfID();
    error notApproverAddress();
    error alreadyApproved();
    error notL1Approver();
    error notL2Approver();
    error L1Rejected();
    error ownerRejectedTheOffer();
    error userContractError();
   
    address private userContract;
    address private L1Approver;
    address private L2Approver;
    string private contracturi;
    string public metadataUri;
    uint private totalLimit;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    
    event OwnershipTransferOfLand(address indexed from, address indexed to, uint indexed tokenId);
    event AccessGrantedToView(address indexed Viewer, uint indexed Token);
    event OwnershipGranted(address to);

    modifier onlyAdmin () {
    if (_msgSender() != owner() && !administrators[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }

    mapping ( address => bool ) private administrators;
    mapping(uint256 => string) private holdUri;
    mapping(uint256 => address) private _owners;
    mapping(address => bool) private approverAddress;
    mapping(uint => uint) private approvecount;
    mapping(address => mapping(uint => bool)) private voteRecord;
    mapping(uint => mapping(address => bool)) private approverDecision;
    mapping(uint => mapping(address => bool)) private landRequest;
    mapping(address => bool) private ownerAcceptLandSales;
    mapping(uint => bool) private saleStatus;
    mapping(uint => string) private registrationDocument;
    mapping(uint => bool) private registrationDocumentStatus;
    mapping(address => mapping(uint => bool)) private L1statusForRequester;
    mapping(address => mapping(uint => bool)) private viewAccessGranted;
    mapping(address => mapping(uint => bool)) private L2statusForRequester;
    mapping(address => mapping(uint => bool)) private L2statusForL1Approver;
    mapping(uint => bool) private L1approverDecision;
    mapping(uint => bool) private L2approverDecision;
    
    struct approverData{
        address _sellingTo;
        uint _tokenId;
        bool status;
    }

    struct approverDataForL2{
        address _previousOwner;
        address _sellingTo;
        uint _tokenId;
        bool status;
    }

    constructor(string memory _metadata) ERC721("Yexele Appian", "Yexele_Land"){
        metadataUri = _metadata;
        totalLimit = 0;
        contracturi = "https://ipfs.io/ipfs/QmSf39izZ2iSHeXpSWKsfDEzqkEfHth6f8LuXdW1Ccge3B";
    }

    function whitelistApproverL1(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }

    function whitelistApproverL2(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L2Approver = _approverAd;
    }

    function whitelistUserContract(address _userContractAd) external onlyAdmin{
        if(_userContractAd == address(0)){ revert zeroAddressNotSupported();}
        userContract = _userContractAd;
    }
   
    /**
        * setContractURI
        * This is sepcifically for setting royalty.
        * @param _contractURI manually set the contract uri json or ipfs hash 
        * When setting the contractURI, make sure it you input both baseuri + tokenuri
    */
    function setContractURI(string memory _contractURI) external onlyAdmin returns(bool){
        contracturi = _contractURI;
        return true;
    } 

    /**
        * Safemint is modified, whereas while minting the token, the tokenURI for the specific token should be entered.
        * @param _to : mint the token to
        * @param _tokenId : token id 
        * @param _tokenUri : tokenURI for the token id.
    */
    function mint(address _to, uint256 _tokenId, string memory _tokenUri) external {
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_to);
        if(!status){ revert userContractError();}
        if(msg.sender == L1Approver){
            holdUri[_tokenId] = bytes(metadataUri).length != 0 ? string(abi.encodePacked(_tokenUri)) : '';
            _mint(_to, _tokenId);
            _owners[_tokenId] = _to;
            totalLimit = totalLimit + 1;
            emit OwnershipTransferOfLand(msg.sender, _to, _tokenId);
        }else{
            revert("Connected address does not have access to create land");
        } 
    }

    /**
        * This function sets the tokenURI if the token belongs to the address.
        * The token owner can set the tokenURI
        * @param _id The token id.
        * @param _tokenUri The token uri string.
    */
    function setTokenURI(uint256 _id, string memory _tokenUri) external {
        require(msg.sender == _owners[_id],"you are not the owner");
        holdUri[_id] = bytes(metadataUri).length != 0
        ? string(abi.encodePacked(_tokenUri))
        : '';
    }

    function approveAndTransferLand1(approverData memory _data) external{
        if(!approverAddress[msg.sender]){ revert notApproverAddress();}
        if(voteRecord[msg.sender][_data._tokenId]){ revert alreadyApproved();}
        if(_data.status == true){
            approverDecision[_data._tokenId][msg.sender] = _data.status;
            voteRecord[msg.sender][_data._tokenId] = true;
            approvecount[_data._tokenId] += 1;
        }
        if(approvecount[_data._tokenId] == 2){
            transferFrom(msg.sender, _data._sellingTo, _data._tokenId);
            emit OwnershipTransferOfLand(msg.sender, _data._sellingTo, _data._tokenId);
        }
    }

    //Write -> Land-view-approval: (L1 approver, letting the buyers to access to view).
    function landDocumentViewRequestApprove(address _requester, uint tokenId, bool _status) external{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        if(msg.sender != L1Approver){ revert notL1Approver();}
        if(_status){
            viewAccessGranted[_requester][tokenId] = true;
            emit AccessGrantedToView(_requester, tokenId);
        }else{
            viewAccessGranted[_requester][tokenId] = false;
        }
    }

    // Buyer requests the land for sale to land owner.
    function requestLandForSale(uint _tokenId) external{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(msg.sender);
        if(!status){ revert userContractError();}
        if(viewAccessGranted[msg.sender][_tokenId]){
            landRequest[_tokenId][msg.sender] = true;
        }else{
            revert("You dont have access");
        }
    }

    //Write -> Buyer decides whether to accept or reject the land.
    function ownerDecisionforRaisedRequest(address _requester, uint _tokenId, bool _status) external{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        require(msg.sender == _owners[_tokenId],"you are not the owner of nft");
        if(viewAccessGranted[_requester][_tokenId] && landRequest[_tokenId][_requester] && _status){
            ownerAcceptLandSales[_requester]= _status;
            saleStatus[_tokenId] = true;
        }else{
            revert("Owner rejected the offer");
        }
    }

    // Write -> Registration Submission by the requester. (If request is approved by the seller, then buyer)
    function registrationForLandByBuyer(uint tokenId, string memory _DocumentUri) external{
        require(ownerAcceptLandSales[msg.sender] == true, "registration is not possible");
        require(saleStatus[tokenId] == true, "sale status is false");
        registrationDocument[tokenId] = _DocumentUri;
        registrationDocumentStatus[tokenId] = true;
    }

    function approveByL1(approverData memory _data) external{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(msg.sender != L1Approver){ revert notL1Approver();}
        if(voteRecord[msg.sender][_data._tokenId]){ revert alreadyApproved();}
        if(registrationDocumentStatus[_data._tokenId] && _data.status == true){
            L1approverDecision[_data._tokenId] = _data.status;
            voteRecord[msg.sender][_data._tokenId] = true;
            L1statusForRequester[_data._sellingTo][_data._tokenId] = true;
            approvecount[_data._tokenId] += 1;
        }else{
            L1statusForRequester[_data._sellingTo][_data._tokenId] = false;
        }
    }

    function approveByL2(approverDataForL2 memory _data) external{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(msg.sender != L2Approver){ revert notL2Approver();}
        if(!L1approverDecision[_data._tokenId]){ revert L1Rejected();}
        if(voteRecord[msg.sender][_data._tokenId]){ revert alreadyApproved();}
        if(_data.status == true){
            L2approverDecision[_data._tokenId] = _data.status;
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
            voteRecord[msg.sender][_data._tokenId] = true;
            approvecount[_data._tokenId] += 1;
        }else{
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
        }
        if(approvecount[_data._tokenId] == 2 && L2approverDecision[_data._tokenId]){
            // Existing owner of NFT needs to provide approve action to let L2 to change ownership
            transferFrom(_data._previousOwner, _data._sellingTo, _data._tokenId);
            _owners[_data._tokenId] = _data._sellingTo;
            emit OwnershipTransferOfLand(msg.sender, _data._sellingTo, _data._tokenId);
        }
    }

    // READ ACTIONS:
    // View Land Document : Owner of Land, L1 and L2 approver can view.
    function viewDocumentByOwnerOrLevelApprovers(address _docViewRequester, uint _tokenId) external view returns(string memory DocumentUri){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(_docViewRequester == _owners[_tokenId] || _docViewRequester == L1Approver || _docViewRequester == L2Approver){
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            return "address is not owner of the land nft or view rights is not provided";
        }
    }

    // View Land Document: (Who ever got access by L1approver can view the doc).
    function viewDocumentByRequesters(address _requester, uint _tokenId) external view returns(string memory DocumentURI){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(viewAccessGranted[_requester][_tokenId] && !saleStatus[_tokenId]){
            if (!_exists(_tokenId)) { revert URIQueryForNonexistentToken(); }
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            revert("View access is denied by L1Approver or The land is listed for sale");
        }
    }

    // Status: All the buyer request can be checked using this read function.
    function LandRequesterStatus(address _requester, uint _tokenId) 
    external 
    view 
    returns(bool ViewDocumentStatus, 
    bool L1ApproverStatusForRequester, 
    bool L2ApproverstatusForRequester, uint approveCountForTokenIdByApprovers){
        return (viewAccessGranted[_requester][_tokenId],
        L1statusForRequester[_requester][_tokenId], 
        L2statusForRequester[_requester][_tokenId], 
        approvecount[_tokenId]);
    }

    // L2 approver status can be checked by the L1 approver.
    function L2ApproverStatusForL1Approver(address _requester, uint _tokenId) external view returns(bool){
        return  L2statusForL1Approver[_requester][_tokenId];
    }

    /**
        * supportsInterface
        * @param interfaceId Pass interfaceId, to let users know whether the ERC standard is used in this contract or not
    */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool){
        return interfaceId == IID_IERC721 || super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}
