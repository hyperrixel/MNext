// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract MNextDataModel {

    /*
     * ###########
     * # STRUCTS #
     * ###########
     */

    // ///////////
    // / GENERIC /
    // ///////////

    struct AccountWithState {
        address account;
        uint8 state;
    }

    // ////////
    // / BANK /
    // ////////

    struct Bank {
        string name;
        string api;
        string site;
        AccountWithState[] accountsBTC;
        address mainAccount;
        AccountWithState[] accounts;
        bytes32[] keys;
        uint8 state;
    }

    // /////////
    // / CHECK /
    // /////////

    struct Check {
        address owner;
        uint256[] coins;
        bytes32 key;
        uint8 state;
    }

    // ////////
    // / COIN /
    // ////////
    //
    // In fact this is the token we use.

    struct Coin {
        address utxo;
        uint256 satoshiId;
        uint16 inUtxoId;
        address owner;
        uint8 state;
    }

    // ////////
    // / NOTE /
    // ////////

    struct Note {
        uint128 nuteTypeId;
        uint256[] coins;
        uint8 state;
    }

    // /////////////
    // / NOTE TYPE /
    // /////////////

    struct NoteType {
        uint256 coinCount;
        string name;
        uint8 state;
    }

    // Users don't have struct for vaious reasons. See documentations for
    // details.

    /*
     * #############
     * # CONSTANTS #
     * #############
     */

    //////////////////
    // ENTITY TYPES //
    //////////////////

    uint8 constant public ENTITY_TYPE_NOT_AVAILABLE = 0;
    uint8 constant public ENTITY_TYPE_BANK = 1;
    uint8 constant public ENTITY_TYPE_USER = 2;

    ////////////
    // STATES //
    ////////////

    // In all states there are some generic designs:
    //  -   1 stands for created state only
    //  -   2 stands for a state where the given object can be used without any
    //        limitations or issues
    //  -  64 stands for suspended state
    //  - 128 stands for deleted state
    //
    // However at the moment states are not switches this design above gives
    // some future-proof attribute to the conception of states in general.
    
    // Since solidity integer values are initialized to 0 it seems to be obvious
    // to use a default value as sign of lack of existence.
    uint8 constant public STATE_UNAVAILABLE = 0;

    // |---------|
    // | ACCOUNT |
    // |---------|

    uint8 constant public ACCOUNT_ADDED = 1;
    uint8 constant public ACCOUNT_ACTIVE = 2;
    uint8 constant public ACCOUNT_SUSPENDED = 64;
    uint8 constant public ACCOUNT_DELETED = 128;

    // |------|
    // | BANK |
    // |------|

    uint8 constant public BANK_CREATED = 1;
    uint8 constant public BANK_ACTIVE_AND_RESTRICTIONLESS = 2;
    uint8 constant public BANK_SUSPENDED = 64;
    uint8 constant public BANK_DELETED = 128;

    // |-------|
    // | CHECK |
    // |-------|

    uint8 constant public CHECK_CREATED = 1;
    uint8 constant public CHECK_ACTIVATED = 2;
    uint8 constant public CHECK_SPENT = 4;
    uint8 constant public CHECK_SUSPENDED = 64;
    uint8 constant public CHECK_DELETED = 128;

    // |------|
    // | COIN |
    // |------|

    uint8 constant public COIN_CREATED = 1;
    uint8 constant public COIN_ACTIVE_AND_FREE = 2;
    uint8 constant public COIN_ACTIVE_IN_CHECK = 4;
    uint8 constant public COIN_ACTIVE_IN_NOTE = 8;
    uint8 constant public COIN_SUSPENDED = 64;
    uint8 constant public COIN_DELETED = 128;
    
    // |------|
    // | NOTE |
    // |------|

    uint8 constant public NOTE_CREATED = 1;
    uint8 constant public NOTE_ACTIVATED = 2;
    uint8 constant public NOTE_SUSPENDED = 64;
    uint8 constant public NOTE_DELETED = 128;

    // |-----------|
    // | NOTE TYPE |
    // |-----------|

    // Some clarifications:
    // - NOTETYPE_AVAILABLE: This kind of note is available to create and to use
    //   (pay and accept).
    // - NOTETYPE_ACCEPTABLE: this kind of note is available for use only. If
    //   this kind of note is payed for a bank account it will be changed to
    //   coins and the note will be deleted.

    uint8 constant public NOTETYPE_CREATED = 1;
    uint8 constant public NOTETYPE_AVAILABLE = 2;
    uint8 constant public NOTETYPE_ACCEPTABLE = 4;
    uint8 constant public NOTETYPE_SUSPENDED = 64;
    uint8 constant public NOTETYPE_DELETED = 128;

    // |------|
    // | USER |
    // |------|

    uint8 constant public USER_CREATED = 1;
    uint8 constant public USER_ACTIVE_AND_RESTRICTIONLESS = 2;
    uint8 constant public USER_SUSPENDED = 64;
    uint8 constant public USER_DELETED = 128;

}