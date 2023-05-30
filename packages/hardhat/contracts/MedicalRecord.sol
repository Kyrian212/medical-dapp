// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MedicalRecord {

    address private owner;

    mapping(bytes32 => Record) private records;
    mapping(address => bool) private authorizedUsers;
    mapping(bytes32 => Restrictions) private accessRestrictions;


    struct Record {
        bytes data;
        uint256 timestamp;
    }


    struct Restrictions {
        mapping(address => bool) authorizedUsers;
        uint8 minRole;
        uint256 expirationDate;
    }


    enum Roles {
        Patient,
        Doctor,
        Administrator
    }


    mapping(address => Roles) private userRoles;


    constructor() {
        owner = msg.sender;
    }


    function authorizeUser(address user) public onlyOwner {
        authorizedUsers[user] = true;
    }


    function removeAuthorization(address user) public onlyOwner {
        authorizedUsers[user] = false;
    }


    function setUserRole(address user, Roles role) public onlyOwner {
        userRoles[user] = role;
    }


    function getRecord(bytes32 key) public view onlyAuthorized returns (bytes memory) {
        Record storage record = records[key];
        Restrictions storage restrictions = accessRestrictions[key];
        require(block.timestamp < restrictions.expirationDate, "This record has expired.");
        require(uint8(userRoles[msg.sender]) >= restrictions.minRole, "Your role is not high enough to access this record.");
        require(restrictions.authorizedUsers[msg.sender], "You are not authorized to access this record.");
        return record.data;
    }


    function setRecord(bytes32 key, bytes memory data, uint256 expirationDate, uint8 minRole, address[] memory _authorizedUsers) public onlyOwner {
        Record storage record = records[key];
        record.data = data;
        record.timestamp = block.timestamp;
        Restrictions storage restrictions = accessRestrictions[key];
        restrictions.expirationDate = expirationDate;
        restrictions.minRole = minRole;
        for (uint i = 0; i < _authorizedUsers.length; i++) {
            restrictions.authorizedUsers[_authorizedUsers[i]] = true;
        }
    }


    function deleteRecord(bytes32 key) public onlyOwner {
        delete records[key];
        delete accessRestrictions[key];
    }


    function getOwner() public view returns (address) {
        return owner;
    }


    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    
    modifier onlyAuthorized {
        require(authorizedUsers[msg.sender], "You are not authorized to perform this action.");
        _;
    }
}