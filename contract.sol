// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MultiSigWallet {
      address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required; // number of confirmations required

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
        uint256 timestamp;   // when submitted
        uint256 expiration;  // 0 means no expiration
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

    bool public paused;
    uint256 public executionDelay; 
    uint256 public txExecutionReward; 
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data,
        uint256 timestamp,
        uint256 expiration
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);

    // Owner/Config events
    event OwnerAdded(address indexed addedOwner);
    event OwnerRemoved(address indexed removedOwner);
    event RequirementChanged(uint256 newRequirement);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);
    event ExecutionRewardChanged(uint256 newReward);
    event ExecutionDelayChanged(uint256 newDelay);

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

    modifier whenNotPaused() {
        require(!paused, "MultiSig: paused");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "MultiSig: only self");
        _;
    }

       constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _executionDelay,
        uint256 _txExecutionReward
    ) {
        require(_owners.length > 0, "MultiSig: owners required");
        require(_required > 0 && _required <= _owners.length, "MultiSig: invalid required number");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "MultiSig: invalid owner");
            require(!isOwner[owner], "MultiSig: owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
        executionDelay = _executionDelay;
        txExecutionReward = _txExecutionReward;
        paused = false;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

      function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint256 _expiration
    ) external onlyOwner whenNotPaused returns (uint256 txId) {
        txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                timestamp: block.timestamp,
                expiration: _expiration
            })
        );

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data, block.timestamp, _expiration);
    }


    function confirmTransaction(uint256 _txId)
        external
        onlyOwner
        whenNotPaused
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    function revokeConfirmation(uint256 _txId)
        external
        onlyOwner
        whenNotPaused
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isConfirmed[_txId][msg.sender], "MultiSig: tx not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    function executeTransaction(uint256 _txId)
        external
        onlyOwner
        whenNotPaused
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];

        // Check expiration (if set)
        if (transaction.expiration != 0) {
            require(block.timestamp <= transaction.expiration, "MultiSig: tx expired");
        }

        // Check timelock delay (if set)
        if (executionDelay != 0) {
            require(block.timestamp >= transaction.timestamp + executionDelay, "MultiSig: timelock not passed");
        }

        require(transaction.numConfirmations >= required, "MultiSig: insufficient confirmations");

        // Effects
        transaction.executed = true;

        // Interaction
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "MultiSig: tx failed");

        // pay executor reward if configured (best-effort, don't revert if send fails)
        if (txExecutionReward > 0) {
            
            if (address(this).balance >= txExecutionReward) {
                (bool sent, ) = payable(msg.sender).call{value: txExecutionReward}("");
                (sent); // we ignore result to avoid reverting on reward failure
            }
        }

        emit ExecuteTransaction(msg.sender, _txId);
    }

   
    function addOwner(address _owner) external onlySelf {
        require(_owner != address(0), "MultiSig: invalid owner");
        require(!isOwner[_owner], "MultiSig: already owner");

        isOwner[_owner] = true;
        owners.push(_owner);

        emit OwnerAdded(_owner);
    }

    
    function removeOwner(address _owner) external onlySelf {
        require(isOwner[_owner], "MultiSig: not owner");

        uint256 len = owners.length;
        for (uint256 i = 0; i < len; i++) {
            if (owners[i] == _owner) {
                // move last into i and pop
                owners[i] = owners[len - 1];
                owners.pop();
                break;
            }
        }

        isOwner[_owner] = false;

        // Adjust required if it's now > owners.length
        if (required > owners.length) {
            required = owners.length;
            emit RequirementChanged(required);
        }

        emit OwnerRemoved(_owner);
    }

    function changeRequirement(uint256 _required) external onlySelf {
        require(_required > 0 && _required <= owners.length, "MultiSig: invalid required number");
        required = _required;
        emit RequirementChanged(_required);
    }

    function pause() external onlySelf {
        paused = true;
        emit Paused(address(this));
    }

     function unpause() external onlySelf {
        paused = false;
        emit Unpaused(address(this));
    }

    function setExecutionReward(uint256 _reward) external onlySelf {
        txExecutionReward = _reward;
        emit ExecutionRewardChanged(_reward);
    }

    function setExecutionDelay(uint256 _delay) external onlySelf {
        executionDelay = _delay;
        emit ExecutionDelayChanged(_delay);
    }

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
            uint256 numConfirmations,
            uint256 timestamp,
            uint256 expiration
        )
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.timestamp,
            transaction.expiration
        );
    }

     function isConfirmedBy(uint256 _txId, address _owner) external view returns (bool) {
        return isConfirmed[_txId][_owner];
    }

     function getPendingTransactionIds() external view returns (uint256[] memory) {
        uint256 total = transactions.length;
        uint256 count = 0;
        for (uint256 i = 0; i < total; i++) {
            if (!transactions[i].executed) count++;
        }

        uint256[] memory ids = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < total; i++) {
            if (!transactions[i].executed) {
                ids[idx] = i;
                idx++;
            }
        }
        return ids;
    }
}

