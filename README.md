# DragonCoin

DragonCoin is an ERC-20 token contract built on Ethereum. It includes features such as taxes on transfers, airdrop functionality, LP token withdrawals, and more. ## Getting Started  ### Prerequisites  - Node.js and npm installed - Truffle framework installed (`npm install -g truffle`) - Ethereum development environment (e.g., [Ganache](https://www.trufflesuite.com/ganache)) 
### Installation  
  **Clone the repository:** 
 ```
 bash git clone https://github.com/BlockJedi/DragonCoin 
 cd DragonCoin
  ```
  
**Install dependencies:**
```
npm install
```
**Copy the `.env.example` file to `.env` and update the values:**
```
cp .env.example .env
```
**Compile the contracts:**
```
truffle compile
```
**Edit `truffle-config.js` to add the desired Ethereum network configurations.**
```
networks: {
  rinkeby: {
    provider: () => new HDWalletProvider(process.env.MNEMONIC, 'https://rinkeby.infura.io/v3/' + process.env.INFURA_API_KEY),
    network_id: 4,
    gas: 5500000,
  },
  // Add more networks as needed
},
```
Replace the placeholder values with your actual Ethereum node URL and Infura API key.

**Compile and Migrate Contracts to the Desired Network:**
```
truffle compile
truffle migrate --network rinkeby
```