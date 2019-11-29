/**
 *Submitted for verification at Etherscan.io on 2018-12-05
*/

pragma solidity ^0.5.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract OpenDegrees is Ownable {
  /// A mapping of the degree hash to the block number that was issued
  mapping(string => string) documentIssued;
  /// A mapping of the hash of the claim being revoked to the revocation block number
  mapping(string => string) documentRevoked;
  ///   A mapping of the address account to the school code
  mapping(address=>string) universityAddressList;
  
  mapping(string=>bool) universityList;
  
  struct Degree{
      string serial_number;
      string hash;
      string universityCode;
  }
  
  mapping(string=>Degree) Degrees;



  event DocumentIssued(string indexed degree_number);
  
  event DocumentRevoked(
    string indexed degree_number
  );
  
  event UniversityAdded(string indexed code);

  function addUniversity(address universityAddress, string memory code) public onlyNotAdded(code) onlyNotUniversity(universityAddress) returns(bool) {
    if (msg.sender==owner){
        universityAddressList[universityAddress]=code;
        universityList[code]=true;
        emit UniversityAdded(code);
        return true;
    }
    return false;
}

  function addDegree(
    string memory degree_number, string memory hash
  ) public onlyUniversity(msg.sender) onlyNotIssued(degree_number)
  {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    documentIssued[string(b)] = hash;
    // Degrees[degree_number].hash=hash;
    // Degrees[degree_number].universityCode = universityAddressList[msg.sender];
    emit DocumentIssued(string(b));
  }
  
  function isUniversity(address _address) public view returns(bool) {
        bytes memory tempEmptyStringTest = bytes(universityAddressList[_address]); // Uses memory
        if (tempEmptyStringTest.length == 0) {
            // emptyStringTest is an empty string
            return false;
        } else {
            // emptyStringTest is not an empty string
            return true;
        }
  }
  
  function isAdded(string memory _code) public view returns(bool){
        bool  tempEmptyStringTest = bool(universityList[_code]); // Uses memory
        if (tempEmptyStringTest == false) {
            // emptyStringTest is an empty string
            return false;
        } else {
            // emptyStringTest is not an empty string
            return true;
        }
  }

  
  
  
  function isIssued(
    string memory degree_number
  ) private view returns (bool)
  {
        string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
        bytes memory tempEmptyStringTest = bytes(documentIssued[string(b)]); // Uses memory
        if (tempEmptyStringTest.length == 0) {
    // emptyStringTest is an empty string
    return false;
} else {
    // emptyStringTest is not an empty string
    return true;
}
   
  }
  
  function verify(string memory _degree_number, string memory _hash, string memory universityCode) public view returns(bool){
        bytes memory b;
        b = abi.encodePacked(universityCode);
        b = abi.encodePacked(b, _degree_number);
      if (keccak256(abi.encodePacked(documentIssued[string(b)])) == keccak256(abi.encodePacked(_hash))){
          return true;
      }
      else{
          return false;
      }
  }


 

  modifier onlyIssued(string memory degree_number, string memory universityCode) {
    // string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(universityCode);
    b = abi.encodePacked(b, degree_number);
      
    require(isIssued(string(b)), "Error: Only issued degree_number hashes can be revoked");
    _;
  }

  modifier onlyNotIssued(string memory degree_number) {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    require(!isIssued(string(b)), "Error: Only hashes that have not been issued can be issued");
    _;
  }
  
  modifier onlyNotAdded(string memory code){
      require(!isAdded(code), "Error: Univeristy code have been added");
      _;
  }
  
  modifier onlyNotUniversity(address univeristyAddress){
      require(!isUniversity(univeristyAddress), "Error: Address already assigned for university");
      _;
  }
  
  modifier onlyUniversity(address univeristyAddress){
      require(isUniversity(univeristyAddress), "Error: Only University can issued degree");
      _;
  }
 
}
