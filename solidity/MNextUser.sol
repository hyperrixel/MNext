// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './MNextNonMaster.sol';

contract MNextUser is MNextNonMaster {

    bytes32 private _userKey;
    
    constructor(address payable master, string memory passPhrase)
                MNextNonMaster(master, payable(msg.sender), ENTITY_TYPE_USER) {

        _userKey = keccak256(abi.encodePacked(passPhrase));

    }

    // TODO: IMLEMENT everything and even more. :-)

}