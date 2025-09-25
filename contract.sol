// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract MultiSigWallet {
    

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required; 

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // txId => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

   

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);

    

    modifier onlyOwner() {
        require(isOwner[msg.sender], "MultiSig: not owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "MultiSig: tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "MultiSig: tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!isConfirmed[_txId][msg.sender], "MultiSig: tx already confirmed");
        _;
    }

  
    
    
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "MultiSig: owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "MultiSig: invalid required number"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "MultiSig: invalid owner");
            require(!isOwner[owner], "MultiSig: owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

   

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }



    
    
   
    
    /// @return txId the id of the submitted transaction
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (uint256 txId) {
        txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }

    /// @notice Confirm a transaction
    /// @param _txId transaction id
    function confirmTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    /// @notice Revoke a prior confirmation
    /// @param _txId transaction id
    function revokeConfirmation(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isConfirmed[_txId][msg.sender], "MultiSig: tx not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    /// @notice Execute a confirmed transaction
    /// @param _txId transaction id
    function executeTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(
            transaction.numConfirmations >= required,
            "MultiSig: insufficient confirmations"
        );

        transaction.executed = true;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "MultiSig: tx failed");

        emit ExecuteTransaction(msg.sender, _txId);
    }

    /* ========== VIEW HELPERS ========== */

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txId)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
