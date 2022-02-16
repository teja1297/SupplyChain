// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract supplyChain {
    uint32 public product_id = 1;   // Product ID
    uint32 public participant_id = 1;   // Participant ID
    uint32 public owner_id = 1;   // Ownership ID
    string[] public participantTypeList =["Manufacturer","Distributor","Wholesaler","Pharmacy"];

    struct Drug {
        string drugName;
        string drugCode;
        address productOwner;
        uint32 cost;
        uint mfgTimeStamp;
        uint expTimeStamp;
        uint32  CurrentTemperature;
        uint32 IdealTemperature;
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



    //fallback function
fallback()external{}

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

    function addProduct(uint32 _ownerId,//change to userID
                        string memory _drugName,
                        string memory _drugCode,
                        string memory _currentLocation,
                        string memory _status,
                        uint32 _productCost,
                        uint32 _manufacturingTimeStamp,
                        uint32 _expiryTimeStamp,
                        uint32 _batchID,
                        uint32 _CurrentTemperature,
                        uint32 _Idealtemperature
                        ) public returns (uint32) {

        require(keccak256(abi.encodePacked(participants[_ownerId].participantType)) == keccak256("Manufacturer")) ;
        
            uint32 productId = product_id++;

            Drugs[productId].drugName = _drugName;
            Drugs[productId].drugCode = _drugCode;
            Drugs[productId].currentLocation = _currentLocation;
            Drugs[productId].cost = _productCost;
            Drugs[productId].productOwner = participants[_ownerId].participantAddress;
            Drugs[productId].mfgTimeStamp = _manufacturingTimeStamp;
            Drugs[productId].expTimeStamp = _expiryTimeStamp;
            Drugs[productId].status = _status;
            Drugs[productId].batchID = _batchID;
            Drugs[productId].CurrentTemperature = _CurrentTemperature;
             Drugs[productId].IdealTemperature = _Idealtemperature;

            return productId;
        

       
    }

   

    function getProduct(uint32 _productId) public view returns (Drug memory drug){
        return ( Drugs[_productId]  );
    }

    function newOwner(uint32 _user1Id,uint32 _user2Id, uint32 _prodId) onlyOwner(_prodId) isExpired(_prodId) isUnderTemp(_prodId) public returns (bool) {
        participant memory p1 = participants[_user1Id];
        participant memory p2 = participants[_user2Id];
        uint32 ownership_id = owner_id++;
        uint  participant_id1;
        uint  participant_id2;

        for(uint i=0;i<participantTypeList.length;i++){
            if(keccak256(abi.encodePacked(p1.participantType)) == keccak256(abi.encodePacked(participantTypeList[i])))
            {
                    participant_id1 =i;
            }
            if(keccak256(abi.encodePacked(p2.participantType)) == keccak256(abi.encodePacked(participantTypeList[i])))
            {
                    participant_id2 =i;
            }
        }

        if((participant_id2 - participant_id1)==1){
             ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            Drugs[_prodId].productOwner = p2.participantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);
            return (true);
        }
        return (false);
    }

   function getProvenance(uint32 _prodId) external view returns (uint32[] memory){

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



 modifier onlyOwner(uint32 _productId) {
         require(msg.sender == Drugs[_productId].productOwner,"");
         _;
}
    

    modifier isExpired(uint32 _productId) {
         if(Drugs[_productId].expTimeStamp < block.timestamp)
         {
             emit Expiry(Drugs[_productId]);
         }
         _;

    }

    modifier isUnderTemp (uint32 _productId) {
         if(Drugs[_productId].CurrentTemperature > Drugs[_productId].IdealTemperature){
             emit overTemp(Drugs[_productId]);
         }
         _;

    }


}
