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
    address public L1Approver;
    address public L2Approver;
    string private contracturi;
    string public metadataUri;
    uint private l1Appovals;
    uint private l2Appovals;
    uint private totalLands;
    uint private completedRegistration;
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
    mapping(address => string[]) private allURI;
    mapping(uint => address[]) private allViewRequesterAddressToView;
    mapping(uint => uint) private noOfRequestsToViewLandDoc;
    mapping(uint => string) private recordUri;
    /**
        * If registrationProcess[tokenId] = false; // Then land is still in process.
        * If registrationProcess[tokenId] = true; // Then land registration is completed.
    */
    mapping(uint => bool) private registrationProcess;
    
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

    /**
        * constructor - ERC721 constructor
        * @param _metadata - base URI : https://ipfs.io/ipfs
    */
    constructor(string memory _metadata) ERC721("Yexele Appian", "Yexele_Land"){
        metadataUri = _metadata;
        totalLimit = 0;
        contracturi = "https://ipfs.io/ipfs/QmSf39izZ2iSHeXpSWKsfDEzqkEfHth6f8LuXdW1Ccge3B";
    }

    /**
        * whitelistApproverL1 - only admin can call this function and set an address as L1 Approver
        * @param _approverAd - address of L1 Approver
    */
    function whitelistApproverL1(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }

    /**
        * whitelistApproverL2 - only admin can call this function and set an address as L2 Approver
        * @param _approverAd - address of L2 Approver
    */
    function whitelistApproverL2(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L2Approver = _approverAd;
    }

    /**
        * whitelistUserContract - only admin can call this function and set an address as userContract address
         and connect this YexleAppian contract with userContract.
        * @param _userContractAd - address of already deployed userContract
    */
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
        * mint - only admin can call this function and mint an ERC721 land token to a user with L1's approval.
        * @param l1Address - address of L1Approver
          @param _to - address of the user to whom the land belongs ERC721 land token will be minted to this address
          @param _tokenId - an integer ID which will represent the ERC721 land token.
          @param _tokenUri - CID hash that points to the documents that are related to the land.
        *
    */
    function mint(address l1Address, address _to, uint256 _tokenId, string memory _tokenUri) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_to);
        if(!status){ revert userContractError();}
        if(l1Address == L1Approver){
            holdUri[_tokenId] = bytes(metadataUri).length != 0 ? string(abi.encodePacked(_tokenUri)) : '';
            _mint(_to, _tokenId);
            _owners[_tokenId] = _to;
            totalLands += 1;
            totalLimit = totalLimit + 1;
            string memory local = string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
            allURI[_to].push(local);
            recordUri[_tokenId] = _tokenUri;
            emit OwnershipTransferOfLand(address(0), _to, _tokenId);
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
        string memory local = string(abi.encodePacked(metadataUri,holdUri[_id]));
        string memory previousUri = string(abi.encodePacked(metadataUri,recordUri[_id]));
        for(uint i = 0; i <  allURI[msg.sender].length; i++){
            string memory uri = allURI[msg.sender][i];
            if(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(previousUri))){
                delete allURI[msg.sender][i];
            }
        }
        recordUri[_id] = _tokenUri;
        allURI[msg.sender].push(local);
    }

    /** 
        *landDocumentViewRequestApprove - only admin can call this function and allow a requesting user to view another user's 
           land documents
          @param l1Address - address of L1 approver
          @param _requester - address of the user requesting to view someone else's land document with intention of buying it
          @param tokenId - tokenID of the land documents which the requester is wishing to see
          @param _status - true or false. true if the admin grants access, false if admin doesn't grant access to requester.
        *
    */
    function landDocumentViewRequestApprove(address l1Address, address _requester, uint tokenId, bool _status) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        if(l1Address != L1Approver){ revert notL1Approver();}
        if(_status){
            viewAccessGranted[_requester][tokenId] = true;
            noOfRequestsToViewLandDoc[tokenId] += 1;
            allViewRequesterAddressToView[tokenId].push(_requester);
            emit AccessGrantedToView(_requester, tokenId);
        }else{
            viewAccessGranted[_requester][tokenId] = false;
        }
    }

    /**
        * requestLandForSale - this function can be called only by Admin. This sends a request from buyer to the land owner 
            expressing the buyer's wish to purchase the land.
        * @param _requester - this is the address of the buyer who wishes to buy a land.
        * @param _tokenId - this is the tokenId of the land documents collection that the buyer wishes to buy.
    */
    function requestLandForSale(address _requester, uint _tokenId) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        if(viewAccessGranted[_requester][_tokenId]){  // whoever willing to buy this land.
            landRequest[_tokenId][_requester] = true;
        }else{
            revert("You dont have access");
        }
    }
     
    /** 
        *ownerDecisionforRaisedRequest - this function can be called only by Admin. This function sets if the owner of the land 
           approves the buyer to purchase his land or not
        *@param oldOwner - address of the seller/owner of the land
        *@param _requester - address of the buyer
        *@param _tokenId - tokenId set to the land documents
        *@param _status - true or false status. true means the owner of the land approves the buyer to purchase his land. 
    */
    function ownerDecisionforRaisedRequest(address oldOwner, address _requester, uint _tokenId, bool _status) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        require(oldOwner == _owners[_tokenId],"you are not the owner of nft");
        if(viewAccessGranted[_requester][_tokenId] && landRequest[_tokenId][_requester] && _status){
            ownerAcceptLandSales[_requester]= _status;
            saleStatus[_tokenId] = true;
        }else{
            revert("Owner rejected the offer");
        }
    }

    /**
        *registrationForLandByBuyer - the buyer submits a request to register the land in his name
        *@param requester - buyer's address
        *@param tokenId - the tokenId of the land documents that buyer wishes to purchase
        *@param _DocumentUri - IPFS URI of the land documents that buyer wishes to purchase
    */
    function registrationForLandByBuyer(address requester, uint tokenId, string memory _DocumentUri) external onlyAdmin{
        require(ownerAcceptLandSales[requester] == true, "registration is not possible");
        require(saleStatus[tokenId] == true, "sale status is false");
        registrationDocument[tokenId] = _DocumentUri;
        registrationDocumentStatus[tokenId] = true;
    }


    /**
        *approveByL1 - L1 approver approves the sale first
        *@param l1Approver - L1 Approver's address
        *@param _data - a struct approverData containing _sellingTo, tokenId and status. sellingTo is address of the buyer, tokenId is
          the tokenId of the land documents and status is true or false status stating if L1 approver approves or not.
    */
    function approveByL1(address l1Approver, approverData memory _data) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(l1Approver != L1Approver){ revert notL1Approver();}
        if(voteRecord[msg.sender][_data._tokenId]){ revert alreadyApproved();}
        if(registrationDocumentStatus[_data._tokenId] && _data.status == true){
            L1approverDecision[_data._tokenId] = _data.status;
            voteRecord[msg.sender][_data._tokenId] = true;
            L1statusForRequester[_data._sellingTo][_data._tokenId] = true;
            l1Appovals += 1;
            approvecount[_data._tokenId] += 1;
        }else{
            L1statusForRequester[_data._sellingTo][_data._tokenId] = false;
        }
    }

    /**
        *approveByL1 - L2 approver approves the sale after L1 approves it.
        *@param l2Approver - L2 Approver's address
        *@param _data - a struct approverDataforL2 containing _previousOwner which is seller address, _sellingTo which has 
         buyer address and status which is true or false status of L2Approver's approval.
    */ 
    function approveByL2(address l2Approver, approverDataForL2 memory _data) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(l2Approver != L2Approver){ revert notL2Approver();}
        if(!L1approverDecision[_data._tokenId]){ revert L1Rejected();}
        if(_data.status == true){
            L2approverDecision[_data._tokenId] = _data.status;
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
            l2Appovals += 1;
            completedRegistration += 1;
            registrationProcess[_data._tokenId] = true; // Then land registration is completed.
            approvecount[_data._tokenId] += 1;
        }else{
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
        }
        if(approvecount[_data._tokenId] == 2 && L2approverDecision[_data._tokenId]){
            // The Owner of NFT needs to provide approve action to let L2 to change ownership
            transferFrom(_data._previousOwner, _data._sellingTo, _data._tokenId);
            string memory local = string(abi.encodePacked(metadataUri,recordUri[_data._tokenId]));
            for(uint i = 0; i <  allURI[_data._previousOwner].length; i++){
                string memory uri = allURI[_data._previousOwner][i];
                if(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(local))){
                    delete allURI[_data._previousOwner][i]; // or delete uri (both are same method).
                }
            }
            allURI[_data._sellingTo].push(local);
            _owners[_data._tokenId] = _data._sellingTo;
            emit OwnershipTransferOfLand(_data._previousOwner, _data._sellingTo, _data._tokenId);
        }
    }

    // /**
    //     * removeUri
    //     * @param index - Enter the index number and delete the array.
    //     * @param _ad - Enter the address of the landOwner.
    // */
    // function removeUri(uint256 index, address _ad) external onlyAdmin{
    //     if (index >= allURI[_ad].length) return;
    //     for (uint i = index; i < allURI[_ad].length - 1; i++) {
    //        allURI[_ad][i] = allURI[_ad][i+1];
    //     }
    //     allURI[_ad].pop();
    // }
    
    // READ FUNCTIONS:
    /**
        *vidwDocumentByOwnerOrLevelApprovers - owner of the land, L1 and L2 approver, these people can view the land documents
        *@param _docViewRequester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function viewDocumentByOwnerOrLevelApprovers(address _docViewRequester, uint _tokenId) external view returns(string memory DocumentUri){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(_docViewRequester == _owners[_tokenId] || _docViewRequester == L1Approver || _docViewRequester == L2Approver){
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            return "address is not owner of the land nft or view rights is not provided";
        }
    }


    // View Land Document: (Who ever got access by L1approver can view the doc).
    /**
        *vidwDocumentByOwnerOrLevelApprovers - owner of the land, L1 and L2 approver, these people can view the land documents
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function viewDocumentByRequesters(address _requester, uint _tokenId) external view returns(string memory DocumentURI){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(viewAccessGranted[_requester][_tokenId] && !saleStatus[_tokenId]){
            if (!_exists(_tokenId)) { revert URIQueryForNonexistentToken(); }
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            revert("View access is denied by L1Approver or The land is listed for sale");
        }
    }

    /**
        *LandRequesterStatus- All the buyer request can be checked using this read function
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
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

    /**
        *L2ApproverStatusForL1Approver- L2 approver status can be checked by the L1 approver.
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function L2ApproverStatusForL1Approver(address _requester, uint _tokenId) external view returns(bool){
        return  L2statusForL1Approver[_requester][_tokenId];
    }

    /**
        * L1ApprovalCounts 
    */
    function L1ApprovalCounts() external view returns(uint totalL1ApprovalCounts){
        return l1Appovals;
    }

    /**
        * L2ApprovalCounts 
    */
    function L2ApprovalCounts() external view returns(uint totalL2ApprovalCounts){
        return l2Appovals;
    }

    /**
        * LandCounts 
    */
    function LandCounts() external view returns(uint totalLandCount){
        return totalLands;
    }

    /**
        * LandRegistrationStatus
    */
    function LandRegistrationStatus(uint _landId) external view returns(bool registrationStatus){
        return registrationProcess[_landId];
    }

    /**
        * CompletedRegistrations
    */
    function completedRegistrations() external view returns(uint totalCompletedRegistrations){
        return completedRegistration;
    }

    /**
        * noOfRequestersInfoToViewDoc 
        * @param tokenId - pass the unique ID which represents the land. created during minting the land NFT
    */
    function noOfRequestersInfoToViewDoc(uint tokenId) external view returns(uint allRequesterCount){
        return noOfRequestsToViewLandDoc[tokenId]; 
    }

    /**
        * returnAllUriForLandOwner
        * @param landOwnerAddress - Enter the land owner address 
    */
    function returnAllUriForLandOwner(address landOwnerAddress) external view returns(string[] memory returnallUris){
        return allURI[landOwnerAddress];
    }

    /**
        * allRequesterAddressForViewDocument.
        * @param _tokenId. 
    */
    function allRequesterAddressForViewDocument(uint _tokenId) external view returns(address[] memory allRequesters){
        return allViewRequesterAddressToView[_tokenId];
    }

    /**
        * supportsInterface
        * @param interfaceId Pass interfaceId, to let users know whether the ERC standard is used in this contract or not
    */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool){
        return interfaceId == IID_IERC721 || super.supportsInterface(interfaceId);
    }

    /**
        * contractURI()
        * Get the contract URI, which can be helpful for royalty setup with opensea. 
    */
    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    /**
        * _baseURI - returns the base IPFS URI where the land documents are stored with their unique CID
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}
