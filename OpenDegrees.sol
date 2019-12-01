pragma solidity ^0.5.11;


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


contract OpenDegreeList is Ownable {
  // Danh sách các văn bằng đã được thêm
  mapping(string => string) degreeIssued;

  // Danh sách các văn bằng đã bị thu hồi
  mapping(string => bool) degreeRevoked;

  // Danh sách các địa chỉ trường Đại học được thêm
  mapping(address => string) universityAddressList;

  // Danh sách các mã trường Đại học được thêm
  mapping(string => address) universityCodeList;




  // Sự kiện sau khi cấp văn bằng
  event DegreeIssued(
    string indexed degree_number
  );

  // Sự kiện sau khi thu hồi văn bằng
  event DegreeRevoked(
    string indexed degree_number
  );

  // Sự kiện sau khi thêm trường Đại học.
  event UniversityAdded(
    string indexed code
  );

  // Hàm: Thêm trường đại học.
  function addUniversity(address universityAddress, string memory code) public onlyUniversityAddressCodeNotAdded(code) onlyNotUniversityAddress(universityAddress) returns(bool) {
    if (msg.sender == owner) {
      universityAddressList[universityAddress] = code;
      universityCodeList[code] = universityAddress;
      emit UniversityAdded(code);
      // Báo thành công
      return true;
    }
    // Báo lỗi
    return false;
  }

  // Hàm: Thêm văn bằng
  function addDegree(
    string memory degree_number, string memory hash
  ) public onlyUniversityAddress(msg.sender) onlyDegreeNotIssued(degree_number) {
    // Xử lý string để tạo ra index của văn bằng = <mã trường><mã bằng>
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    degreeIssued[string(b)] = hash;
    emit DegreeIssued(string(b));
  }

  // Hàm: thu hồi văn bằng
  function revokeDegree(
    string memory degree_number
  ) public onlyUniversityAddress(msg.sender) onlyDegreeNotRevokedCanRevoked(degree_number) onlyDegreeIssuedCanRevoked(degree_number) {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    degreeRevoked[string(b)] = true;

    emit DegreeRevoked(string(b));
  }



  // Phương thức: xác minh văn bằng
  function verify(string memory _degree_number, string memory _hash, string memory universityCode) public view returns(uint256) {
    bytes memory b;
    b = abi.encodePacked(universityCode);
    b = abi.encodePacked(b, _degree_number);
    if (keccak256(abi.encodePacked(degreeIssued[string(b)])) == keccak256(abi.encodePacked(_hash))) {
      if (degreeRevoked[string(b)]) {
        // Văn bằng đã bị thu hồi
        return 2;
      }
      // Văn bằng khả dụng
      return 1;
    } else {
      // Văn bằng không hợp lệ.
      return 0;
    }
  }

  // Kiểm tra: địa chỉ có phải địa chỉ của trường Đại học không? 
  function isUniversity(address _address) private view returns(bool) {
    bytes memory tempEmptyStringTest = bytes(universityAddressList[_address]);
    if (tempEmptyStringTest.length == 0) {
      return false;
    } else {
      return true;
    }
  }

  // Kiểm tra: mã có phải là mã của trường Đại học không?
  function isUniversityCode(string memory _code) private view returns(bool) {
    address tmp_address = address(universityCodeList[_code]);
    if (tmp_address != address(0)) {

      return true;
    } else {

      return false;
    }
  }


  // Lấy mã của trường Đại học.
  function getUniversityCode(address _university_address) public view returns(string memory) {
    string memory tmp = universityAddressList[_university_address];
    return tmp;
  }

  // Kiểm tra văn bằng đã được cấp chưa?
  function isDegreeIssued(
    string memory degree_number
  ) private view returns(bool) {

    bytes memory tempEmptyStringTest = bytes(degreeIssued[degree_number]); // Uses memory
    if (tempEmptyStringTest.length == 0) {
      return false;
    } else {
      return true;
    }

  }

  // Kiểm tra văn bằng đã được thu hồi chưa?
  function isDegreeRevoked(
    string memory degree_number
  ) private view returns(bool) {


    return degreeRevoked[degree_number];

  }



  // Chỉ văn bằng đã được cấp mới có thể thu hồi.
  modifier onlyDegreeIssuedCanRevoked(string memory degree_number) {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    require(isDegreeIssued(string(b)), "Lỗi: Chỉ văn bằng được đưa lên mới có thể thêm");
    _;
  }

  //Chỉ văn bằng chưa bị thu hồi mới có thể bị thu hồi. 
  modifier onlyDegreeNotRevokedCanRevoked(string memory degree_number) {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    require(!isDegreeRevoked(string(b)), "Lỗi: Chỉ văn bằng chưa bị thu hồi mới có thể  thu hồi");
    _;
  }

  // Chỉ văn bằng đã được cấp
  modifier onlyDegreeIssued(string memory degree_number, string memory universityCode) {
    // string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(universityCode);
    b = abi.encodePacked(b, degree_number);

    require(isDegreeIssued(string(b)), "Lỗi: Chỉ văn bằng đã được thêm mới có thể thu hồi.");
    _;
  }

  // Chỉ văn bằng chưa được cấp
  modifier onlyDegreeNotIssued(string memory degree_number) {
    string memory index = universityAddressList[msg.sender];
    bytes memory b;
    b = abi.encodePacked(index);
    b = abi.encodePacked(b, degree_number);
    require(!isDegreeIssued(string(b)), "Lỗi: Chỉ văn bằng  chưa được đưa lên mới có thể thêm");
    _;
  }

  // Chỉ mã trường chưa được thêm.
  modifier onlyUniversityAddressCodeNotAdded(string memory code) {
    require(!isUniversityCode(code), "Lỗi: Mã trường bị trùng");
    _;
  }

  // Chỉ địa chỉ trường chưa được thêm.
  modifier onlyNotUniversityAddress(address univeristyAddress) {
    require(!isUniversity(univeristyAddress), "Lỗi: Mỗi địa chỉ chỉ có thể đăng ký 1 trường");
    _;
  }

  // Chỉ địa chỉ của trường Đại học.
  modifier onlyUniversityAddress(address univeristyAddress) {
    require(isUniversity(univeristyAddress), "Lỗi: Bạn không phải là trường, bạn không có quyền thực hiện thao tác này");
    _;
  }

}
