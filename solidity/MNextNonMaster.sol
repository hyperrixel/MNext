// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './MNextDataModel.sol';
import './MNextMaster.sol';

contract MNextNonMaster is MNextDataModel {

    /*
     * #####################
     * # PRIVATE VARIABLES #
     * #####################
     */

    // Local check book, it contains system level IDs only
    uint256[] private _checks;

    // Master contract's address
    address payable private _master;
    // Master contract's instance
    MNextMaster private _masterContract;
    // Contract's address
    address payable private _self;
    // Since this is a base contract it can serve multiple entity types
    uint8 private _entityType;
    
    /*
     * Contract constructor
     * --------------------
     * Construct the contract
     *
     * @param address payable master_
     *        Address of the master contract.
     * @param address payable self_
     *        Address of the contract itself.
     * @param uint8 entityType_
     *        Type of the entity represented by the contract.
     */
    constructor(address payable master_, address payable self_,
                uint8 entityType_) {

        _master = master_;
        _masterContract = MNextMaster(master_);
        _self = self_;
        _entityType = entityType_;

    }

    /*
     * #############################
     * # Contract property getters #
     * #############################
     */

    /*
     * Get entity type
     * ---------------
     * Get the entity type of the contract owner
     *
     * @reutrn uint8
     *         The entity type. For entity types see documentation.
     */
    function getEntityType() external view returns (uint8) {

        return _entityType;

    }
    
    /*
     * Get master address
     * ------------------
     * Get the address of the master contract
     *
     * @reutrn address
     *         The address of the master contract.
     */
    function getMaster() external view returns (address payable) {

        return _master;

    }

    /*
     * Get contract owner address
     * --------------------------
     * Get the address that the contract is registered for
     *
     * @reutrn address
     *         The address of the contract owner.
     */
    function getSelf() external view returns (address payable) {

        return _self;

    }

    /*
     * ###########################
     * # Checks of account owner #
     * ###########################
     *
     * In fact these functions belong to _checks
     */
    
    ////////////
    // CREATE //
    ////////////

    /*
     * Create check
     * ------------
     * Create a check without activation
     *
     * @param string memory passPhrase
     *        A pharese to secure the check.
     * @param uint256 amount
     *        The amount of the check.
     */
    function createActiveCheck(string memory passPhrase, uint256 amount)
                         onlySelf external returns (uint256) {

        
        // Depending on EVM configuration delegatecall() should be used here.
        uint256 thisId = _masterContract.createActiveCheck(amount, passPhrase);
        _checks.push(thisId);
        return thisId;

    }

    /*
     * Create check
     * ------------
     * Create a check with activation
     *
     * @param string memory passPhrase
     *        A pharese to secure the check.
     * @param uint256 amount
     *        The amount of the check.
     */
    function createCheck(string memory passPhrase, uint256 amount) onlySelf
                         external returns (uint256) {

        
        // Depending on EVM configuration delegatecall() should be used here.
        uint256 thisId = _masterContract.createCheck(amount, passPhrase);
        _checks.push(thisId);
        return thisId;

    }

    //////////
    // READ //
    //////////

    /*
     * Get a check
     * -----------
     * Get data of a checks
     *
     * @param uint256 myId
     *        Entity level ID in the register. It differs from the system ID.
     */
    function getCheck(uint256 myId) onlyExistingCheck(myId) external view
                      returns (Check memory) {

        return _masterContract.getCheck(_checks[myId]);

    }

    /*
     * Get all checks
     * --------------
     * Get a full list of checks
     *
     * @return Check[] memory
     *         List of all checks.
     */
    function getChecks() external view returns (Check[] memory) {

        Check[] memory result = new Check[](_checks.length);
        for (uint256 i=0; i<_checks.length; i++)
            result[i] = _masterContract.getCheck(_checks[i]);
        return result;

    }
    
    ////////////
    // UPDATE //
    ////////////

    /*
     * Activate check
     * --------------
     * Activate a non activated check
     *
     * @param uint256 myId
     *        Entity level ID in the register. It differs from the system ID.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function activateCheck(uint256 myId, string calldata passPhrase)
                           onlyExistingCheck(myId) external {

        // Depending on EVM configuration delegatecall() should be used here.
        _masterContract.activateCheck(_checks[myId], passPhrase);

    }
    
    /*
     * Clear check
     * -----------
     * Clear an active check
     *
     * @param uint256 id
     *        Sytem level ID of the check.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function clearCheck(uint256 id, address from, string calldata passPhrase)
                        external {

        // Depending on EVM configuration delegatecall() should be used here.
        _masterContract.clearCeck(id, from, passPhrase);

    }

    /*
     * Suspend check
     * -------------
     * Suspend an existing and non suspended check
     *
     * @param uint256 myId
     *        Entity level ID in the register. It differs from the system ID.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function suspendCheck(uint256 myId, string calldata passPhrase)
                          onlyExistingCheck(myId) external {

        // Depending on EVM configuration delegatecall() should be used here.
        _masterContract.suspendCheck(_checks[myId], passPhrase);

    }

    ////////////
    // DELETE //
    ////////////

    /*
     * Delete a check
     * --------------
     * Delete a not yet cleared check
     *
     * @param uint256 myId
     *        Entity level ID in the register. It differs from the system ID.
     * @param string memory passPhrase
     *        A pharese to secure the check.
     */
    function deleteCheck(uint256 myId, string calldata passPhrase)
                         onlyExistingCheck(myId) external {

        // Depending on EVM configuration delegatecall() should be used here.
        _masterContract.deleteCheck(_checks[myId], passPhrase);

    }


    /*
     * ######################
     * # INTERNAL FUNCTIONS #
     * ######################
     */

    /*
     * Get master contract
     * -------------------
     * Provide internal access to master contract without new instantiation
     *
     * @return The instantiated master contract.
     */
    function _getMasterContract() internal view returns (MNextMaster) {

        return _masterContract;

    }

    /*
     * #############
     * # MODIFIERS #
     * #############
     */
    
    /*
     * Check existence of a check
     * --------------------------
     * Check whether a check exists locally or not
     *
     * @param uint256 myId
     *        The local ID of the check to check.
     */
    modifier onlyExistingCheck(uint256 myId) {

        require(myId < _checks.length, 'Check not exists.');
        _;

    }
    
    /*
     * Check the user
     * --------------
     * Check whether the operator is the owner of the contract or not
     */
    modifier onlySelf() {

        require(msg.sender == _self,
                'Owner only action.');
        _;
        
    }

}