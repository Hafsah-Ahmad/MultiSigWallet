                          MultiSig Wallet (with Timelock, Daily Limit, and Expiration)

A Multi-Signature Wallet smart contract written in Solidity.
This wallet requires a predefined number of owner approvals before executing transactions.
It includes additional advanced features like timelock, daily spending limit, transaction expiration, pause/unpause, and executor rewards.

 Features=
✅ Multiple owners with customizable confirmation requirements
✅ Timelock (delay between submission & execution)
✅ Transaction expiration support
✅ Daily spending limit
✅ Pause / unpause the contract (emergency stop)
✅ Add/remove owners via consensus
✅ Execution reward (optional gas reimbursement for executor)
✅ Full Hardhat project with scripts & tests

 Tech Stack=
-Solidity ^0.8.28
-Hardhat (development & testing)
-Chai / Mocha (unit testing)
-Ethers.js (deployment & interaction)

Getting Started=
1. Clone repo & install dependencies
git clone https://github.com/your-username/MultiSigWallet.git
cd MultiSigWallet
npm install
2. Compile contracts
npx hardhat compile
3. Run tests
npx hardhat test
4. Deploy to local network

Start a local Hardhat node:
-npx hardhat node
-In a new terminal, deploy the contract:
-npx hardhat run scripts/deploy.js --network localhost

 Usage Example (scripts/interact.js)

The provided script demonstrates:

Submitting a transaction

Confirming by another owner

Executing the transaction

Run it with:

npx hardhat run scripts/interact.js --network localhost

⚙️ Constructor Parameters

When deploying, provide:

address[] _owners → array of wallet owners

uint256 _required → number of confirmations required

uint256 _executionDelay → timelock in seconds

uint256 _txExecutionReward → fixed reward for executors (in wei)

Example:

owners = [0x123..., 0x456..., 0x789...]
required = 2
executionDelay = 60       // 60 seconds timelock
txExecutionReward = 10000 // optional reward in wei

🔑 Key Functions

submitTransaction(address to, uint value, bytes data, uint expiration)

confirmTransaction(uint txId)

revokeConfirmation(uint txId)

executeTransaction(uint txId)

addOwner(address owner)

removeOwner(address owner)

pause() / unpause()

setExecutionReward(uint reward)

setExecutionDelay(uint delay)

getTransaction(uint txId)

🧪 Testing

The tests cover:

Deployment

Submitting, confirming, and executing a transaction

Requiring multiple confirmations

Timelock enforcement

Expiration logic

Daily spending limits

Run:

npx hardhat test
Notes

The contract is upgrade-safe (no hard-coded owners).

Use pause() in emergencies to stop new transactions.

Executor rewards are optional and only paid if the contract has sufficient balance.

Author

Developed by Hafsa Ahmad ✨


 License

This project is licensed under the MIT License.