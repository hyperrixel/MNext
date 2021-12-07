// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * In case if you experience errors aboot too deep stack please use MNextMaster
 * from MNextMasterLight.sol.
 *
 * It performs less checks which means less security on one hand but
 * compatibility with common configured EVMs like this of Ethereum ecosystem
 * on the other hand.
 *
 * To see the differences please read the leading comment in the file
 * MNextMasterLight.sol.
 */

import './MNextDataModel.sol';

contract MNextMaster is MNextDataModel{
    
    /*
     * ###########
     * # STRUCTS #
     * ###########
     */

    // ////////
    // / BANK /
    // ////////

    struct BankWrapper {
        Bank bank;
        bool isLocked;
    }

    // /////////
    // / CHECK /
    // /////////

    struct CheckWrapper {
        Check check;
        bool isLocked;
    }

    // ////////
    // / USER /
    // ////////

    struct User {
        uint8 state;
        bool isLocked;
    }
    
    // //////////////
    // / UTXO (BTC) /
    // //////////////

    struct BTCutxo {
        address utxo;
        uint256 satoshi;
        uint16 bank;
        uint256 account;
    }

    /*
     * ####################
     * # PUBLIC VARIABLES #
     * ####################
     */

    //////////////////////////////
    // SYSTEM'S KEY DESCRIPTORS //
    //////////////////////////////

    string public name;
    string public token;
    string public symbol;
    string public admin;
    string public api;
    string public site;
    string public explorer;
    
    mapping (uint8 => NoteType) public noteTypes;

    /*
     * #####################
     * # PRIVATE VARIABLES #
     * #####################
     */

    /////////////////////////////
    // SYSTEM'S KEY CONTAINERS //
    /////////////////////////////

    mapping (uint16 => BankWrapper) private _banks;
    mapping (uint256 => CheckWrapper) private _checks;
    mapping (uint256 => Coin) private _coins;
    mapping (uint256 => Note) private _notes;
    mapping (address => User) private _users;
    mapping (uint256 => BTCutxo) private _utxos;

    /////////////////////////////
    // SYSTEM'S KEY CONDITIONS //
    /////////////////////////////

    uint256 private _satoshiBase;
    int32 private _reserveRatio;
    uint16 private _multiplier;

    /////////////////////////
    // MAINTENANCE HELPERS //
    /////////////////////////

    uint16 private _nextBankId;
    uint256 private _nextCoinId;
    uint256 private _nextNoteId;
    uint256 private _nextCheckId;
    uint256 private _utxoPointer;

    ////////////////////////////////
    // SYSTEM ADMIN'S CREDENTIALS //
    ////////////////////////////////

    address payable private _rootUser;
    bytes32 private _rootKey;

    /*
     * Contract constructor
     * --------------------
     * Construct the contract
     *
     * @param string memory sentence
     *        A sentence to protect master access.
     * @param uint256 satoshiBase_
     *        Value to set as system's base unit.
     * @param int32 reserveRatio_
     *        Value to set as system's reserve ratio.
     * @param uint16 multiplier_
     *        Value to set as system's multiplier.
     */
    constructor(string memory sentence, uint256 satoshiBase_,
                int32 reserveRatio_, uint16 multiplier_) payable {
        
        _rootUser = payable(msg.sender);
        _rootKey = keccak256(abi.encodePacked(sentence));
        _satoshiBase = satoshiBase_;
        _reserveRatio = reserveRatio_;
        _multiplier = multiplier_;

        /*
         * SETUP BTC GATEWAY.
         */

        _nextBankId = 0;
        _nextCheckId = 0;
        _nextCoinId = 0;
        _nextNoteId = 0;

    }

    // C A U T I O N ! ! !
    //
    // Don't forget to remove the section below in production to save the system
    // tokens.
    
    /*
     * ##################
     * # Mock functions #
     * ##################
     */

    /*
     * Get mock coins
     * --------------
     * Create mock coins to the caller
     *
     * @param uint256 amount
     *        Amount of coins to create.
     */
    function mockCreateCoins(uint256 amount) external {

        _users[msg.sender].state = USER_ACTIVE_AND_RESTRICTIONLESS;
        for (uint256 i=0; i<amount; i++) {
            _coins[i] = Coin(address(0), i, 0, msg.sender, COIN_ACTIVE_AND_FREE);
            _nextCoinId++;
        }

    }

    /*
     * Get mock coins
     * --------------
     * Create mock coins to a foreign user
     *
     * @param address user
     *        Address of the user to create mock coins for.
     * @param uint256 amount
     *        Amount of coins to create.
     */
    function mockCreateUserWithBalance(address user, uint256 amount) external {

        _users[user].state = USER_ACTIVE_AND_RESTRICTIONLESS;
        for (uint256 i=0; i<amount; i++) {
            _coins[i] = Coin(address(0), i, 0, user, COIN_ACTIVE_AND_FREE);
            _nextCoinId++;
        }

    }

    /*
     * Mock transaction between users
     * ------------------------------
     * Perform mock transaction between foreign users
     *
     * @param address sender
     *        Address of the user to send mock coins from.
     * @param address target
     *        Address of the user to send mock coins to.
     * @param uint256 amount
     *        Amount of coins to create.
     *
     * @note Please keep in mind, though it's a mock transaction function, it
     *       calls the real inside _transact() function. So sender must have
     *       enough coins to send. The function mockCreateCoins() is useful to
     *       help you out.
     */
    function mockTransact(address sender, address target, uint256 amount)
                          external returns (bool) {

        return _transact(sender, target, amount);

    }


    /*
     * #########################
     * # End of mock functions #
     * #########################
     */

    // Don't forget to remove the section above in production to save the system
    // tokens.
    //
    // C A U T I O N ! ! !

    /*
     * ########################
     * # System level actions #
     * ########################
     */

    /*
     * Review coin supply
     * ------------------
     * Review the coin supply of the system
     */
    function review() external {

        _utxoPointer = 0;
        for (uint16 i=0; i < _nextBankId; i++) __reviewBank(i);
        __reviewCoins();

    }

    /*
     * Set system admin name
     * ---------------------
     * Set the name of the system's admin
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newAdmin
     *        The new name of the admin.
     */
    function setAdmin(string calldata sentence, string calldata newAdmin)
                      onlyAdmin(sentence) external {

        admin = newAdmin;

    }

    /*
     * Set system API root
     * -------------------
     * Set the link to the system's API root
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newApi
     *        The new link to the API root.
     */
    function setApi(string calldata sentence, string calldata newApi)
                    onlyAdmin(sentence) external {

        api = newApi;

    }

    /*
     * Set system explorer
     * -------------------
     * Set the link to the system's data explorer
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newExplorer
     *        The new link to the explorer.
     */
    function setExplorer(string calldata sentence, string calldata newExplorer)
                         onlyAdmin(sentence) external {

        explorer = newExplorer;

    }

    /*
     * Set multiplier
     * --------------
     * Set the value of the system's multiplier
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param uint16 newMultiplier_
     *        The new multiplier value.
     */
    function setMultiplier(string calldata sentence, uint16 newMultiplier_)
                           onlyAdmin(sentence) external {

        _multiplier = newMultiplier_;
        this.review();

    }

    /*
     * Set system name
     * --------------
     * Set the name of the system
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newName
     *        The new name of the system.
     */
    function setName(string calldata sentence, string calldata newName)
                     onlyAdmin(sentence) external {

        name = newName;

    }

    /*
     * Set reserve ratio
     * -----------------
     * Set the value of the system's reserve ratio
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param int32 newReserveRatio_
     *        The new reserve ratio value.
     *
     * @note Since solidity doesn't handle fractions, to set the percentage
     *       value you have to multiply the original (fraction) value with 100.
     */
    function setReserveRatio(string calldata sentence, int32 newReserveRatio_)
                             onlyAdmin(sentence) external {

        _reserveRatio = newReserveRatio_;
        this.review();

    }

    /*
     * Set satoshi base
     * ----------------
     * Set the value of the system's Satoshi base
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param uint256 newSatoshiBase_
     *        The new Satoshi base value.
     */
    function setSatoshiBase(string calldata sentence, uint256 newSatoshiBase_)
                            onlyAdmin(sentence) external {

        _satoshiBase = newSatoshiBase_;
        this.review();

    }

    /*
     * Set system homepage
     * -------------------
     * Set the link to the system's homepage
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newSite
     *        The new link to the homepage.
     */
    function setSite(string calldata sentence, string calldata newSite)
                     onlyAdmin(sentence) external {

        site = newSite;

    }

    /*
     * Set token symbol
     * ----------------
     * Set the symbol of the system's token
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newSymbol
     *        The new symbol of the token.
     */
    function setSymbol(string calldata sentence, string calldata newSymbol)
                       onlyAdmin(sentence) external {

        symbol = newSymbol;

    }

    /*
     * Set token name
     * --------------
     * Set the name of the system's token
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newToken
     *        The new name of the token.
     */
    function setToken(string calldata sentence, string calldata newToken)
                      onlyAdmin(sentence) external {

        token = newToken;

    }

    /*
     * ############################
     * # System level information #
     * ############################
     */

    /*
     * Get multiplier
     * --------------
     * Get the value of the system's multiplier
     *
     * @return uint16
     *         The actual multiplier value.
     */
    function getMultiplier() external view returns (uint16) {

        return _multiplier;

    }

    /*
     * Get reserve ratio
     * -----------------
     * Get the value of the system's reserve ratio
     *
     * @return int32
     *         The actual reserve ratio value.
     *
     * @note Since solidity doesn't handle fractions, to receive the percentage
     *       value you have to divide the returned value with 100.
     */
    function getReserveRatio() external view returns (int32) {

        return _reserveRatio;

    }

    /*
     * Get satoshi base
     * ----------------
     * Get the value of the system's Satoshi base
     *
     * @return uint256
     *         The actual Satoshi base value.
     */
    function getSatoshiBase() external view returns (uint256) {

        return _satoshiBase;

    }

    /*
     * Get active coin count
     * ---------------------
     * Get the count of active coins in the system
     *
     * @return uint256
     *         The actual count of active coins.
     */
    function getCoinCount() external view returns (uint256) {

        uint256 result = 0;
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].state == COIN_ACTIVE_AND_FREE
                || _coins[i].state == COIN_ACTIVE_IN_CHECK
                || _coins[i].state == COIN_ACTIVE_IN_NOTE)
                result++;
        return result;

    }

    /*
     * #########
     * # Banks #
     * #########
     */
    
    ////////////
    // CREATE //
    ////////////

    /*
     * Create bank
     * -----------
     * Create (register) a bank
     *
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata bankName
     *        The name of the bank to register.
     * @param address mainAccount
     *        An address to be used as the bank's main account.
     * @param string calldata firstPassPhrase
     *        A password phrase to be used as the first [0] security key.
     */
    function createBank(string calldata sentence, string calldata bankName,
                        address mainAccount, string calldata firstPassPhrase)
                        onlyAdmin(sentence) lockBank(_nextBankId) external
                        returns (uint16) {

        uint16 thisId = _nextBankId;
        bytes32[] memory keyArray = new bytes32[] (1);
        keyArray[0] = keccak256(abi.encodePacked(firstPassPhrase));
        _banks[thisId].bank.name = bankName;
        _banks[thisId].bank.api = '';
        _banks[thisId].bank.site = '';
        delete _banks[thisId].bank.accountsBTC;
        _banks[thisId].bank.mainAccount = mainAccount;
        delete _banks[thisId].bank.accounts;
        delete _banks[thisId].bank.keys;
        _banks[thisId].bank.state = BANK_CREATED;
        _nextBankId++;
        return thisId;

    }

    //////////
    // READ //
    //////////

    /*
     * Get a bank
     * ----------
     * Get data of a bank
     *
     * @param uint16 id
     *        ID of the check.
     *
     * @return Bank memory
     *         The data of the given bank.
     *
     * @note Keys of the bank rest hidden.
     */
    function getBank(uint16 id) external view returns (Bank memory) {

        bytes32[] memory keyArray = new bytes32[] (0);
        Bank memory result = _banks[id].bank;
        result.keys = keyArray;
        return result;

    }

    
    /*
     * Get bank count
     * --------------
     * Get the count of all banks.
     *
     * @return uin16
     *         The count of the banks.
     */
    function getBankCount() external view returns (uint16) {

        return _nextBankId;

    }

    /*
     * Get all banks
     * -------------
     * Get data of all banks
     *
     * @return Bank[] memory
     *         List of data of all banks.
     *
     * @note Keys of banks rest hidden.
     */
    function getBanks() external view returns (Bank[] memory) {

        Bank[] memory result = new Bank[](_nextBankId);
        bytes32[] memory keyArray = new bytes32[] (0);
        for (uint16 i=0; i < _nextBankId; i++) {
            result[i] = _banks[i].bank;
            result[i].keys = keyArray;
        }
        return result;

    }

    ////////////
    // UPDATE //
    ////////////

    /*
     * TODO IMPLEMENT
     * 
     * BTC accounts:
     * - addBankBTCAccount(uint16 id, string calldata sentence, address btcAccount)
     * - addBankBTCAccount(uint16 id, uint256 keyId, string calldata passPhrase, address btcAccount)
     * - activateBankBTCAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - activateBankBTCAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     * - deleteBankBTCAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - deleteBankBTCAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     * - suspendBankBTCAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - suspendBankBTCAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     *
     * Note: BTC account related functions autamotically call review()
     *
     * System accounts:
     * - addBankAccount(uint16 id, string calldata sentence, address account)
     * - addBankAccount(uint16 id, uint256 keyId, string calldata passPhrase, address account)
     * - activateBankAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - activateBankAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     * - deleteBankAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - deleteBankAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     * - suspendBankAccount(uint16 id, uint256 accountId, string calldata sentence)
     * - suspendBankAccount(uint16 id, uint256 accountId, uint256 keyId, string calldata passPhrase)
     *
     * - addBankKey(string calldata sentence, string calldata passPhrase)
     * - addBankKey(uint256 keyId, string calldata passPhrase, string calldata passPhrase)
     * - changeBankKey(uint16 id, uint256 affectedKeyId, string calldata sentence, string calldata newPassPhrase)
     * - changeBankKey(uint16 id, uint256 affectedKeyId, uint256 keyId, string calldata passPhrase, string calldata newPassPhrase)
     *
     * TODO: CHANGE
     *
     * - More complex key validation system.
     */

    /*
     * Activate bank
     * -------------
     * Activate a non activated bank
     *
     * @param uint16 id
     *        The ID of the bank to activate.
     * @param string calldata sentence
     *        A sentence to protect master access.
     */
    function activateBank(uint16 id, string calldata sentence)
                          onlyAdmin(sentence) onlyExistingBank(id) lockBank(id)
                          external {

        require(_banks[id].bank.state == BANK_CREATED,
                'Cannot activate bank with a non appropriate state.');
        _banks[id].bank.state = BANK_ACTIVE_AND_RESTRICTIONLESS;

    }

    /*
     * Set API site link of a bank
     * ---------------------------
     * Set the link to the API root of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newApi
     *        The new API site link to set.
     */
    function setBankApi(uint16 id, string calldata sentence,
                        string calldata newApi) onlyAdmin(sentence)
                        onlyExistingBank(id) lockBank(id) external {

        _banks[id].bank.api = newApi;

    }
    
    /*
     * Set API site link of a bank
     * ---------------------------
     * Set the link to the API root of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param uint256 keyId
     *        The ID of the key to valIdate transaction with.
     * @param string calldata passPhrase
     *        A password phrase that matches the key to grant access.
     * @param string calldata newApi
     *        The new API site link to set.
     */
    function setBankApi(uint16 id, uint256 keyId, string calldata passPhrase,
                        string calldata newApi) onlyExistingBank(id)
                        lockBank(id) onlyValIdBankAction(id, keyId, passPhrase)
                        external {

        _banks[id].bank.api = newApi;

    }

    /*
     * Set name of a bank
     * ------------------
     * Set the name of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newName
     *        The new name to set.
     */
    function setBankName(uint16 id, string calldata sentence,
                         string calldata newName) onlyAdmin(sentence)
                         onlyExistingBank(id) lockBank(id) external {

        _banks[id].bank.name = newName;

    }
    
    /*
     * Set name of a bank
     * ------------------
     * Set the name of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param uint256 keyId
     *        The ID of the key to valIdate transaction with.
     * @param string calldata passPhrase
     *        A password phrase that matches the key to grant access.
     * @param string calldata newName
     *        The new name to set.
     */
    function setBankName(uint16 id, uint256 keyId, string calldata passPhrase,
                         string calldata newName) onlyExistingBank(id)
                         lockBank(id) onlyValIdBankAction(id, keyId, passPhrase)
                         external {

        _banks[id].bank.name = newName;

    }

    /*
     * Set homepage link of a bank
     * ---------------------------
     * Set the link to the homepage of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param string calldata sentence
     *        A sentence to protect master access.
     * @param string calldata newSite
     *        The new homepage link to set.
     */
    function setBankSite(uint16 id, string calldata sentence,
                         string calldata newSite) onlyAdmin(sentence)
                         onlyExistingBank(id) lockBank(id) external {

        _banks[id].bank.site = newSite;

    }
    
    /*
     * Set homepage link of a bank
     * ---------------------------
     * Set the link to the homepage of the bank
     *
     * @param uint16 id
     *        The ID of the bank.
     * @param uint256 keyId
     *        The ID of the key to valIdate transaction with.
     * @param string calldata passPhrase
     *        A password phrase that matches the key to grant access.
     * @param string calldata newSite
     *        The new homepage link to set.
     */
    function setBankSite(uint16 id, uint256 keyId, string calldata passPhrase,
                         string calldata newSite) onlyExistingBank(id)
                         lockBank(id) onlyValIdBankAction(id, keyId, passPhrase)
                         external {

        _banks[id].bank.site = newSite;

    }

    /*
     * Suspend bank
     * ------------
     * Suspend am active bank
     *
     * @param uint16 id
     *        The ID of the bank to suspend.
     * @param string calldata sentence
     *        A sentence to protect master access.
     */
    function suspendBank(uint16 id, string calldata sentence)
                         onlyAdmin(sentence) onlyExistingBank(id) lockBank(id)
                         external {

        require(_banks[id].bank.state == BANK_SUSPENDED
                || _banks[id].bank.state == BANK_DELETED,
                'Cannot suspend a bank with a non appropriate state.');
        _banks[id].bank.state = BANK_SUSPENDED;

    }

    ////////////
    // DELETE //
    ////////////

    /*
     * Delete bank
     * -----------
     * Delete an existing bank
     *
     * @param uint16 id
     *        The ID of the bank to delete.
     * @param string calldata sentence
     *        A sentence to protect master access.
     */
    function deleteBank(uint16 id, string calldata sentence) onlyAdmin(sentence)
                        onlyExistingBank(id) lockBank(id) external {

        require(_banks[id].bank.state == BANK_DELETED,
                'Cannot delete an already deleted bank.');
        _banks[id].bank.state = BANK_DELETED;

    }

    /*
     * ##########
     * # Checks #
     * ##########
     */
    
    ////////////
    // CREATE //
    ////////////

    /*
     * Create check
     * ------------
     * Create a check without activation
     *
     * @param uint256 amount
     *        The amount of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function createActiveCheck(uint256 amount, string calldata passPhrase)
                               lockUser(msg.sender) external returns (uint256) {

        return _createCheck(amount, passPhrase, CHECK_ACTIVATED);

    }

    /*
     * Create check
     * ------------
     * Create a check with activation
     *
     * @param uint256 amount
     *        The amount of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function createCheck(uint256 amount, string calldata passPhrase)
                         lockUser(msg.sender) external returns (uint256) {

        return _createCheck(amount, passPhrase, CHECK_CREATED);

    }

    //////////
    // READ //
    //////////

    /*
     * Get a check
     * -----------
     * Get data of a check
     *
     * @param uint256 id
     *        ID of the check.
     *
     * @note Check's key is hIdden. This way the key of the check cannot be
     *       retrieved. This design decision pushes big responsibility to the
     *       end-users' application.
     */
    function getCheck(uint256 id) external view returns (Check memory) {

        return Check(_checks[id].check.owner, _checks[id].check.coins,
                     '', _checks[id].check.state);

    }

    /*
     * Get check value
     * ---------------
     * Get the value of a check
     *
     * @param uint256 id
     *        ID of the check.
     *
     * @return uint256
     *         The value of the given check.
     */
    function getCheckValue(uint256 id) external view returns (uint256) {

        return _checks[id].check.coins.length;

    }

    ////////////
    // UPDATE //
    ////////////

    /*
     * Activate check
     * --------------
     * Activate a non activated check
     *
     * @param uint256 id
     *        ID of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function activateCheck(uint256 id, string calldata passPhrase) lockCheck(id)
                           onlyValIdCheckAction(id, msg.sender, passPhrase)
                           external {

        require(_checks[id].check.state == CHECK_CREATED
                || _checks[id].check.state == CHECK_SUSPENDED,
                'Cannot activate a check from a non appropriate state.');
        _checks[id].check.state = CHECK_ACTIVATED;

    }
    
    /*
     * Clear check
     * -----------
     * Clear an active check
     *
     * @param uint256 id
     *        ID of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function clearCeck(uint256 id, address from, string calldata passPhrase)
                       lockUser(msg.sender) lockUser(from)
                       lockCheck(id) onlyValIdCheckAction(id, from, passPhrase)
                       external {

        require(_checks[id].check.state == CHECK_ACTIVATED,
                'Cannot clear a non active check.');
        require(_checks[id].check.owner == from,
                'Original owner is needed to clear check.');
        require(_checks[id].check.key == keccak256(abi.encodePacked(passPhrase)),
                'Cannot clear a not opened check.');
        // Note: consider to do this after the for loop. It is a hard decision.
        _checks[id].check.state = CHECK_SPENT;
        // There's no lack of {}s in the for loop and if selector below. :-)
        for (uint256 i=0; i < _checks[id].check.coins.length; i++)
            if (_coins[_checks[id].check.coins[i]].owner != from
                || _coins[_checks[id].check.coins[i]].state != COIN_ACTIVE_IN_CHECK)
                revert('Internal error: Check clearance refused, safety first.');
            else _coins[_checks[id].check.coins[i]].owner = msg.sender;

    }

    /*
     * Suspend check
     * -------------
     * Suspend an existing and non suspended check
     *
     * @param uint256 id
     *        ID of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function suspendCheck(uint256 id, string calldata passPhrase) lockCheck(id)
                          onlyValIdCheckAction(id, msg.sender, passPhrase)
                          external {

        require((_checks[id].check.state == CHECK_CREATED
                || _checks[id].check.state == CHECK_ACTIVATED),
                'Cannot perform suspending on check with non appropriate state.');
        _checks[id].check.state = CHECK_SUSPENDED;

    }

    ////////////
    // DELETE //
    ////////////

    /*
     * Delete a check
     * --------------
     * Delete a not yet cleared check
     *
     * @param uint256 id
     *        ID of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function deleteCheck(uint256 id, string calldata passPhrase) lockCheck(id)
                         onlyValIdCheckAction(id, msg.sender, passPhrase)
                         external {

        require((_checks[id].check.state == CHECK_CREATED
                || _checks[id].check.state == CHECK_ACTIVATED
                || _checks[id].check.state == CHECK_SUSPENDED),
                'Cannot perform deletioon on check with non appropriate state.');
        // There's no lack of {} in the for loop below. :-)
        for (uint i=0; i < _checks[id].check.coins.length; i++)
            _coins[_checks[id].check.coins[i]].state = COIN_ACTIVE_AND_FREE;
        _checks[id].check.state = CHECK_DELETED;

    }

    /*
     * #########
     * # Notes #
     * #########
     */

    // TODO: IMPLEMENT

    /*
     * ##############
     * # Note types #
     * ##############
     */

    // TODO: IMPLEMENT

    /*
     * ###############################
     * # User balance and user coins #
     * ###############################
     */

    /*
     * Get the balance of a user
     * -------------------------
     * Get the total balance of a user
     *
     * @param address owner
     *        The address of the user to get balance for.
     *
     * @return uint256
     *         The balance of the user.
     */
    function getBalance(address owner) external view returns (uint256) {

        uint256 result = 0;
        // There's no lack of {} in the for loop below. :-)
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == owner) result += 1;
        return result;

    }

    /*
     * Get the coins of a user
     * -----------------------
     * Get the list of all coins of a user
     *
     * @param address owner
     *        The address of the user to get coins for.
     *
     * @return uint256[]
     *         List if IDs of the coins of the user.
     */
    function getCoins(address owner) external view returns (uint256[] memory) {

        // Becuse .push() is not available on memory arrays, a non-gas-friendly
        // workaround should be used.
        uint256 counter = 0;
        // There's no lack of {} in the for loop below. :-)
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == owner) counter++;
        uint256[] memory result = new uint256[](counter);
        counter = 0;
        // There's no lack of {} in the for loop below. :-)
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == owner) {
                result[counter] = i;
                counter++;
            }
        return result;

    }

    /*
     * ################
     * # TRANSACTIONS #
     * ################
     */
    
    /*
     * Transact between users
     * ----------------------
     * Perform transaction between users
     *
     * @param address target
     *        Target address to send coins to.
     * @param uint256 amount
     *        Amount of coins to send.
     *
     * @return bool
     *         True if the transaction was successful, false if not.
     *
     * @note In most cases like ERC20 token standard event is imetted on
     *       successful transactions. In this ecosystem the function transact()
     *       is called by MNextUser contract, therefore it is more convenient
     *       to return bool instead of emitting an event. Emitting event can
     *       happen in the user's contract depending on the implementation.
     */
    function transact(address target, uint256 amount) lockUser(msg.sender)
                      lockUser(target) external returns (bool) {

        return _transact(msg.sender, target, amount);

    }

    /*
     * Transact between banks
     * ----------------------
     * Perform transaction between banks
     *
     * @param uint16 id
     *        ID of a bank to transact from.
     * @param uint256 keyId
     *        The ID of the key to valIdate transaction with.
     * @param string calldata passPhrase
     *        A password phrase that matches the key to grant access.
     * @param uint16 target
     *        ID of a bank to transact to.
     * @param uint256 amount
     *        Amount of coins to send.
     *
     * @return bool
     *         True if the transaction was successful, false if not.
     *
     * @note In most cases like ERC20 token standard event is imetted on
     *       successful transactions. In this ecosystem the function transact()
     *       is called by MNextBank contract, therefore it is more convenient
     *       to return bool instead of emitting an event. Emitting event can
     *       happen in the bank's contract depending on the implementation.
     */
    function transactBankToBank(uint16 id, uint256 keyId,
                                string calldata passPhrase, uint16 target,
                                uint256 amount) onlyExistingBank(id)
                                lockBank(id)
                                onlyValIdBankAction(id, keyId, passPhrase)
                                onlyExistingBank(target) lockBank(target)
                                external returns (bool) {

        return _transact(_banks[id].bank.mainAccount,
                         _banks[target].bank.mainAccount, amount);

    }

    /*
     * Transact from bank to user
     * --------------------------
     * Perform transaction from a bank to a user
     *
     * @param uint16 id
     *        ID of a bank to transact from.
     * @param uint256 keyId
     *        The ID of the key to valIdate transaction with.
     * @param string calldata passPhrase
     *        A password phrase that matches the key to grant access.
     * @param address target
     *        Target address to send coins to.
     * @param uint256 amount
     *        Amount of coins to send.
     *
     * @return bool
     *         True if the transaction was successful, false if not.
     *
     * @note In most cases like ERC20 token standard event is imetted on
     *       successful transactions. In this ecosystem the function transact()
     *       is called by MNextBank contract, therefore it is more convenient
     *       to return bool instead of emitting an event. Emitting event can
     *       happen in the bank's contract depending on the implementation.
     */
    function transactBankToUser(uint16 id, uint256 keyId,
                                string calldata passPhrase, address target,
                                uint256 amount) onlyExistingBank(id)
                                lockBank(id)
                                onlyValIdBankAction(id, keyId, passPhrase)
                                onlyExistingUser(target) lockUser(target)
                                external returns (bool) {

        return _transact(_banks[id].bank.mainAccount, target, amount);
        
    }

    /*
     * Transact from user to bank
     * --------------------------
     * Perform transaction from a user to a bank
     *
     * @param uint16 target
     *        ID of a bank to transact to.
     * @param uint256 amount
     *        Amount of coins to send.
     *
     * @return bool
     *         True if the transaction was successful, false if not.
     *
     * @note In most cases like ERC20 token standard event is imetted on
     *       successful transactions. In this ecosystem the function transact()
     *       is called by MNextUser contract, therefore it is more convenient
     *       to return bool instead of emitting an event. Emitting event can
     *       happen in the user's contract depending on the implementation.
     */
    function transactUserToBank(uint16 target, uint256 amount)
                                lockUser(msg.sender) lockBank(target)
                                external returns (bool) {

        return _transact(msg.sender, _banks[target].bank.mainAccount, amount);

    }

    // TODO: IMPLEMENT if bank want to use other than mainAccount both for
    //       bank->bank, bank->user and user->bank transactions.

    /*
     * ######################
     * # INTERNAL FUNCTIONS #
     * ######################
     */

    /*
     * Create check with state
     * -----------------------
     * Create a check with the given state
     *
     * @param uint256 amount
     *        The amount of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     * @param uint8 state
     *        The state to create check with.
     */
    function _createCheck(uint256 amount, string calldata passPhrase,
                          uint8 state) lockCheck(_nextCheckId)
                          private returns (uint256) {

        // Becuse .push() is not available on memory arrays, a non-gas-friendly
        // workaround should be used.
        uint256 counter = 0;
        // There's no lack of {} in the for loop below. :-)
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == msg.sender
                                && _coins[i].state == COIN_ACTIVE_AND_FREE)
                counter++;
        require(counter >= amount,
                'Not enough balance to create chekk.');
        uint256[] memory coins = new uint256[](counter);
        counter = 0;
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == msg.sender
                                && _coins[i].state == COIN_ACTIVE_AND_FREE) {
                _coins[i].state = COIN_ACTIVE_IN_CHECK;
                coins[counter] = i;
                counter++;
                if (counter > amount) break;
            }
        uint256 _thisId = _nextCheckId;
        if (_checks[_thisId].isLocked)
            revert('Internal error: Check creation refused, safety first.');
        _checks[_thisId].check = Check(msg.sender, coins,
                                       keccak256(abi.encodePacked(passPhrase)),
                                       state);
        _nextCheckId++;
        return _thisId;

    }

    /*
     * Transact
     * --------
     * Perform transaction between addresses
     *
     * @param address owner
     *        Target address to send coins from.
     * @param address target
     *        Target address to send coins to.
     * @param uint256 amount
     *        Amount of coins to send.
     *
     * @return bool
     *         True if the transaction was successful, false if not.
     */
    function _transact(address owner, address target, uint256 amount)
                       internal returns (bool) {

        bool result = false;
        uint256[] memory coinSupply = new uint256[] (amount);
        uint256 counter = 0;
        for (uint256 i=0; i < _nextCoinId; i++)
            if (_coins[i].owner == owner
                && _coins[i].state == COIN_ACTIVE_AND_FREE) {
                coinSupply[counter] = i;
                counter++;
                if (counter == amount) {
                    result = true;
                    break;
                }
            }
        if (result) {
            for (uint256 i=0; i < coinSupply.length; i++)
                _coins[i].owner = target;
        }
        return result;

    }

    /*
     * #####################
     * # PRIVATE FUNCTIONS #
     * #####################
     */

    /*
     * Review utxo deposits of a bank
     * ------------------------------
     * Collects information about presenting utxo deposits of the given bank
     *
     * @param uint16 id
     *        The ID of the bank to review.
     */
    function __reviewBank(uint16 id) onlyExistingBank(id) lockBank(id) private {

        for (uint256 i=0; i<_banks[id].bank.accountsBTC.length; i++) {

            /*
             * ACCES BTC GATEWAY.
             */
            
            uint256 responseLength = 0;
            address[] memory utxoList = new address[] (responseLength);
            uint256[] memory amountList = new uint256[] (responseLength);
            require(utxoList.length == amountList.length, 'BTC gateway error.');
            for (uint256 j=0; j < utxoList.length; j++) {
                _utxos[_utxoPointer] = BTCutxo(utxoList[j], amountList[j], id, i);
                _utxoPointer++;
            }
            
        }
    
    
    }

    /*
     * Review all the system coins
     * ---------------------------
     * Review system coins whether hey have the needed BTC deposits or not
     */
    function __reviewCoins() private {

        // HOW IT WORKS?
        // 1. Gets all available utxos
        // 2. Loops over coins and marks missing utxos
        // 3. If there are coins without deposits, attempts to swap or delete them
        // 4. If there are utxos without coins, they might used to coin swap
        // 5. If there are utxos withoot coins after swaps, attempts to create coins
        // 6. If something important happen in this functions events are mitted

    }

    /*
     * #############
     * # MODIFIERS #
     * #############
     */

    /*
     * Lock a bank
     * -----------
     * Attempt to lock a bank during its data gets changed
     *
     * @param uint16 id
     *        The ID of the bank to lock.
     */
    modifier lockBank(uint16 id) {
        require(!_banks[id].isLocked,
                'Cannot perform action on a locked bank.');
        _banks[id].isLocked = true;
        _;
        _banks[id].isLocked = false;
    }
    
    /*
     * Lock a check
     * ------------
     * Attempt to lock a check during its data gets changed
     *
     * @param uint256 id
     *        The ID of the check to lock.
     */
    modifier lockCheck(uint256 id) {
        require(!_checks[id].isLocked,
                'Cannot perform action on a locked check.');
        _checks[id].isLocked = true;
        _;
        _checks[id].isLocked = false;
    }
    
    /*
     * Lock a user
     * -----------
     * Attempt to lock a user during its data gets changed
     *
     * @param address wallet
     *        The wallet of the user to lock.
     */
    modifier lockUser(address wallet) {
        require(!_users[wallet].isLocked,
                'Cannot perform action on a locked user.');
        _users[wallet].isLocked = true;
        _;
        _users[wallet].isLocked = false;
    }
    
    /*
     * ValIdate admin
     * --------------
     * ValIdate access of the master contract owner
     *
     * @param string memory sentence
     *        A sentence to protect master access.
     */
    modifier onlyAdmin(string memory sentence) {

        require(msg.sender == _rootUser,
                'Only admin can perform the action.');
        require(keccak256(abi.encodePacked(sentence)) == _rootKey,
                'Authorization failed.');
        _;

    }

    /*
     * Check existence of a bank
     * -------------------------
     * Check whether a bank exists or not
     *
     * @param uint16 id
     *        The ID of the bank to check.
     */
    modifier onlyExistingBank(uint16 id) {
        
        require(_banks[id].bank.state != STATE_UNAVAILABLE,
                'Bank id must exist.');
        _;

    }

    /*
     * Check existence of a check
     * --------------------------
     * Check whether a check exists or not
     *
     * @param uint256 id
     *        The ID of the check to check.
     */
    modifier onlyExistingCheck(uint256 id) {
        
        require(_checks[id].check.state != STATE_UNAVAILABLE,
                'Check id must exist.');
        _;

    }

    /*
     * Check existence of a coin
     * -------------------------
     * Check whether a coin exists or not
     *
     * @param uint256 id
     *        The ID of the coin to check.
     */
    modifier onlyExistingCoin(uint256 id) {
        
        require(_coins[id].state != STATE_UNAVAILABLE,
                'Coin id must exist.');
        _;

    }

    /*
     * Check existence of a note
     * -------------------------
     * Check whether a note exists or not
     *
     * @param uint256 id
     *        The ID of the note to check.
     */
    modifier onlyExistingNote(uint256 id) {
        
        require(_notes[id].state != STATE_UNAVAILABLE,
                'Note id must exist.');
        _;

    }

    /*
     * Check existence of a user
     * -------------------------
     * Check whether a user exists locally or not
     *
     * @param address who
     *        The address of the user to check.
     */
    modifier onlyExistingUser(address who) {
        
        require(_users[who].state != STATE_UNAVAILABLE
                && _users[who].state != USER_DELETED,
                'User must exist.');
        _;

    }

    modifier onlyValIdBankAction(uint16 id, uint256 keyId,
                                 string calldata passPhrase) {

        require(_banks[id].bank.keys.length < keyId,
                'Cannot valIdate a non existing key.');
        require(_banks[id].bank.keys[keyId]
                == keccak256(abi.encodePacked(passPhrase)),
                'Authorization failed.');
        _;

    }

    /*
     * ValIdate check access
     * ---------------------
     * ValIdate access credentials to perform actions on a check
     *
     * @param uint256 id
     *        ID of the check.
     * @param address owner
     *        The address of owner of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    modifier onlyValIdCheckAction(uint256 id, address owner,
                                  string calldata passPhrase) {

        require(_checks[id].check.owner == owner,
                'Cannot perform action on a foreign check.');
        require(_checks[id].check.key
                == keccak256(abi.encodePacked(passPhrase)),
                'Cannot perform action on a not opened check.');
        _;

    }

}