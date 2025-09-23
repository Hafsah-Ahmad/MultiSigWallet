// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract MultiSigWallet {
    /* ========== STATE VARIABLES ========== */
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public confirmed;

    /* ========== EVENTS ========== */
    event Submit(uint indexed txId, address indexed to, uint value, bytes data);
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    /* ========== MODIFIERS ========== */
    modifier onlyOwner() {
        _;
    }

    modifier txExists(uint _txId) {
        _;
    }

    modifier notExecuted(uint _txId) {
        _;
    }

    modifier notConfirmed(uint _txId) {
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(address[] memory _owners, uint _required) {
        // TODO: set owners and required confirmations
    }

    /* ========== FUNCTIONS ========== */
    function submitTransaction(address _to, uint _value, bytes memory _data) 
        public 
        onlyOwner 
    {
        // TODO: store new transaction
    }

    function confirmTransaction(uint _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
        notConfirmed(_txId) 
    {
        // TODO: mark confirmation
    }

    function executeTransaction(uint _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        // TODO: 
    }

    function revokeConfirmation(uint _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        
    }
}
