# MNext

MNext is a token community platform for banks and end users with online and offline payment solutions and coin multiplication techniques to provide a cutting edge monetary system. Tokens are unified and bitcoin-bonded with all characteristics of a fiat currency.

## How to use

🔦 There are two ways to try out MNext.

1. If you have RSK Testnet tokens you can use the address ` 0x3Ad64B7087e39ffa18a9B27ad4dd1B61b7c283d1 ` to try out the smart contract.

2. If you want to try out root functions as well you can deploy the contract from the GitHub repository. For the RSK network you have to deploy ` MNextMaster ` from the file ` MNextMasterLight.sol  ` to avoid errors about stack depth. You also need the file ` MNextDataModel.sol ` for structures and constants.

Once you have deployed the smart contract you can test its functions.

There are some mock functions to fuel up the contrac.

` mockCreateCoins(uint256 amount) `

With this function you can activate yourself and you can get some coins to test the contract.

` mockCreateUserWithBalance(address user, uint256 amount) `

With this function you can activate imaginary users and you can give some coins to them.

` mockTransact(address sender, address target, uint256 amount) `

With this function you can transact between two foreign users. If you want to send your coins to other users you can use the non-mock version of transact as well.

If you already activated yourself you can do non-mock transactions with your coins. If you deployed the contract to your own address you can try out root (admin) functions as well.

To try check functions you have to have two accounts with some coins at least on the account which creates a check.

## About the mock UI

Our User Interface is just a mock at the moment. It shows key concepts of our idea and it also has some additional information like an introduction for an imaginary future user. The mock UI contains the 3 most basic screens and potential forward to functional screens. It is important to mention that this mock UI is just a potential version of the in-production service. There are a lot of possibilities to add functions and design depending on the end-user needs.

Since our smart contracts can be easily subclassed there is endless potential for additional smart services.

## Further links

[Mock UI](https://hyperrixel.com/hackathon/mnext/)

[GitHub](https://github.com/hyperrixel/MNext)

[YouTube](https://youtu.be/5TFfpMe43Vk)

[Devpost](https://devpost.com/software/mnext)

Smart Contract on RSK Testnet: ` 0x3Ad64B7087e39ffa18a9B27ad4dd1B61b7c283d1 `
