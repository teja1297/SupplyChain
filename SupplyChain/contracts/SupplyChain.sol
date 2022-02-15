// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract supplyChain {
    uint32 public product_id = 0;   // Product ID
    uint32 public participant_id = 0;   // Participant ID
    uint32 public owner_id = 0;   // Ownership ID
    uint public temparatureControl = 5;

    struct Drug {
        string drugName;
        string drugCode;
        address productOwner;
        uint32 cost;
        uint32 mfgTimeStamp;
        uint32 expTimeStamp;
        uint8  temperature;
        uint32 batchID;
        string currentLocation;
        string status;
    }

    mapping(uint32 => Drug) public Drugs;

    struct participant {
        string userName;
        string password;
        string participantType;
        address participantAddress;
    }
    mapping(uint32 => participant) public participants;

    struct ownership {
        uint32 productId;
        uint32 ownerId;
        uint32 trxTimeStamp;
        address productOwner;
    }
    mapping(uint32 => ownership) public ownerships; // ownerships by ownership ID (owner_id)
    mapping(uint32 => uint32[]) public productTrack;  // ownerships by Product ID (product_id) / Movement track for a product
    event TransferOwnership(uint32 productId);
    event Expiry(Drug drug);
    event overTemp(Drug drug);
    
    function addParticipant(string memory _name, string memory _pass, address _pAdd, string memory _pType) public returns (uint32){
        uint32 userId = participant_id++;
        participants[userId].userName = _name;
        participants[userId].password = _pass;
        participants[userId].participantAddress = _pAdd;
        participants[userId].participantType = _pType; // should only be Manufacturer,Distributor,Wholesaler,Pharmacy

        return userId;
    }

    function getParticipant(uint32 _participant_id) public view returns (string memory,address,string memory) {
        return (participants[_participant_id].userName,
                participants[_participant_id].participantAddress,
                participants[_participant_id].participantType);
    }

    function addProduct(uint32 _ownerId,
                        string memory _drugName,
                        string memory _drugCode,
                        string memory _currentLocation,
                        string memory _status,
                        uint32 _productCost,
                        uint32 _manufacturingTimeStamp,
                        uint32 _expiryTimeStamp,
                        uint32 _batchID,
                        uint8 _temperature
                        ) public returns (uint32) {

        if(keccak256(abi.encodePacked(participants[_ownerId].participantType)) == keccak256("Manufacturer")) {
            uint32 productId = product_id++;

            products[productId].drugName = _drugName;
            products[productId].drugCode = _drugCode;
            products[productId].currentLocation = _currentLocation;
            products[productId].cost = _productCost;
            products[productId].productOwner = participants[_ownerId].participantAddress;
            products[productId].mfgTimeStamp = _manufacturingTimeStamp;
            products[productId].expTimeStamp = _expiryTimeStamp;
            products[productId].status = _status;
            products[productId].batchID = _batchID;
            products[productId].temperature = _temperature;

            return productId;
        }

       return 0;
    }

    modifier onlyOwner(uint32 _productId) {
         require(msg.sender == products[_productId].productOwner,"");
         _;

    }
    
    modifier isExpired(uint32 _productId) {
         if(products[_prodId].expTimeStamp < uint32(now))
         {
             emit Expiry(products[_prodId]);
         }
         _;

    }

    modifier isUnderTemp (uint32 _productId) {
         if(products[_prodId].temperature > temparatureControl){
             emit OverTemp(products[_prodId]);
         }
         _;

    }


    function getProduct(uint32 _productId) public view returns (string memory,string memory,string memory,uint32,string memory,string memory,uint32,uint32,uint32,uint8){
        return (products[productId].drugName ,
            products[productId].drugCode,
            products[productId].currentLocation ,
            products[productId].cost ,
            products[productId].productOwner ,
            products[productId].mfgTimeStamp ,
            products[productId].expTimeStamp,
            products[productId].status ,
            products[productId].batchID ,
            products[productId].temperature);
    }

    function newOwner(uint32 _user1Id,uint32 _user2Id, uint32 _prodId) onlyOwner(_prodId),isExpired(_prodId),isUnderTemp(_prodId) public returns (bool) {
        participant memory p1 = participants[_user1Id];
        participant memory p2 = participants[_user2Id];
        uint32 ownership_id = owner_id++;
        require();
        if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Manufacturer")
            && keccak256(abi.encodePacked(p2.participantType))==keccak256("Distributor")){

            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(now);
            products[_prodId].productOwner = p2.participantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);
            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Distributor") && keccak256(abi.encodePacked(p2.participantType))==keccak256("Wholesaler")){
            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(now);
            products[_prodId].productOwner = p2.participantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);

            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Wholesaler") && keccak256(abi.encodePacked(p2.participantType))==keccak256("Pharmacy")){
            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(now);
            products[_prodId].productOwner = p2.participantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);

            return (true);
        }

        return (false);
    }

   function getProvenance(uint32 _prodId) external view returns (uint32[] memory) {

       return productTrack[_prodId];
    }

    function getOwnership(uint32 _ownership_id)  public view returns (uint32,uint32,address,uint32) {

        ownership memory r = ownerships[_ownership_id];

         return (r.productId,r.ownerId,r.productOwner,r.trxTimeStamp);
    }

    function authenticateParticipant(uint32 _uid,
                                    string memory _uname,
                                    string memory _pass,
                                    string memory _utype) public view returns (bool){
        if(keccak256(abi.encodePacked(participants[_uid].participantType)) == keccak256(abi.encodePacked(_utype))) {
            if(keccak256(abi.encodePacked(participants[_uid].userName)) == keccak256(abi.encodePacked(_uname))) {
                if(keccak256(abi.encodePacked(participants[_uid].password)) == keccak256(abi.encodePacked(_pass))) {
                    return (true);
                }
            }
        }

        return (false);
    }
}
