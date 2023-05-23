module overmind::nftango {
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenId};
    use std::option::{Self, Option};
    use std::vector;
    use std::signer;
    use std::string::{Self, String};

    //
    // Errors
    //
    const ERROR_NFTANGO_STORE_EXISTS: u64 = 0;
    const ERROR_NFTANGO_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_NFTANGO_STORE_IS_ACTIVE: u64 = 2;
    const ERROR_NFTANGO_STORE_IS_NOT_ACTIVE: u64 = 3;
    const ERROR_NFTANGO_STORE_HAS_AN_OPPONENT: u64 = 4;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT: u64 = 5;
    const ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET: u64 = 6;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN: u64 = 7;
    const ERROR_NFTANGO_STORE_HAS_CLAIMED: u64 = 8;
    const ERROR_NFTANGO_STORE_IS_NOT_PLAYER: u64 = 9;
    const ERROR_VECTOR_LENGTHS_NOT_EQUAL: u64 = 10;

    //
    // Data structures
    //
    struct NFTangoStore has key {
        creator_token_id: TokenId,
        // The number of NFTs (one more more) from the same collection that the opponent needs to bet to enter the game
        join_amount_requirement: u64,
        opponent_address: Option<address>,
        opponent_token_ids: vector<TokenId>,
        active: bool,
        has_claimed: bool,
        did_creator_win: Option<bool>,
        signer_capability: account::SignerCapability
    }

    /// This turns a u128 into its UTF-8 string equivalent.
    public fun u128_to_string(value: u128): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    //
    // Assert functions
    //
    public fun assert_nftango_store_exists(
        account_address: address,
    ) {
        // TODO: assert that `NFTangoStore` exists
        let store_exists = exists<NFTangoStore>(account_address);
        assert!(store_exists, ERROR_NFTANGO_STORE_DOES_NOT_EXIST);        
    }

    public fun assert_nftango_store_does_not_exist(
        account_address: address,
    ) {
        // TODO: assert that `NFTangoStore` does not exist
        let store_exists = exists<NFTangoStore>(account_address);
        assert!(!store_exists, ERROR_NFTANGO_STORE_EXISTS);
    }

    public fun assert_nftango_store_is_active(
        account_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.active` is active
        let store = borrow_global<NFTangoStore>(account_address);
        assert!(
            store.active, 
            ERROR_NFTANGO_STORE_IS_NOT_ACTIVE
        );   
    }

    public fun assert_nftango_store_is_not_active(
        account_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.active` is not active
        let store = borrow_global<NFTangoStore>(account_address);
        assert!(
            !store.active, 
            ERROR_NFTANGO_STORE_IS_ACTIVE
        );   
    }

    public fun assert_nftango_store_has_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.opponent_address` is set
        let store = borrow_global<NFTangoStore>(account_address);
        assert!(
            option::is_some(&store.opponent_address), 
            ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT
        );   

    }

    public fun assert_nftango_store_does_not_have_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.opponent_address` is not set
        let store = borrow_global<NFTangoStore>(account_address);
        assert!(
            option::is_none(&store.opponent_address),
            ERROR_NFTANGO_STORE_HAS_AN_OPPONENT
        );   
    }

    public fun assert_nftango_store_join_amount_requirement_is_met(
        game_address: address,
        opponent_address: address,
        token_ids: vector<TokenId>,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.join_amount_requirement` is met
        let store = borrow_global<NFTangoStore>(game_address);
        let sum_amount = 0;
        let index = 0;
        let len = vector::length(&token_ids);
        while(index < len) {
            let token_id = *vector::borrow(&token_ids, index);
            let token_amount = token::balance_of(opponent_address, token_id);
            sum_amount = sum_amount + token_amount;
            index = index + 1;
        };
        assert!(
            store.join_amount_requirement == sum_amount, 
            ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET
        );   
    }

    public fun assert_nftango_store_has_did_creator_win(
        game_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.did_creator_win` is set
        let store = borrow_global<NFTangoStore>(game_address);
        assert!(
            store.did_creator_win == option::some(true), 
            ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN
        );   
    }

    public fun assert_nftango_store_has_not_claimed(
        game_address: address,
    ) acquires NFTangoStore {
        // TODO: assert that `NFTangoStore.has_claimed` is false
        let store = borrow_global<NFTangoStore>(game_address);
        assert!(
            !store.has_claimed, 
            ERROR_NFTANGO_STORE_HAS_CLAIMED
        );   
    }

    public fun assert_nftango_store_is_player(account_address: address, game_address: address) acquires NFTangoStore {
        // TODO: assert that `account_address` is either the equal to `game_address` or `NFTangoStore.opponent_address`
        let store = borrow_global<NFTangoStore>(game_address);
        assert!(
            account_address == game_address || store.opponent_address == option::some<address>(account_address), 
            ERROR_NFTANGO_STORE_IS_NOT_PLAYER
        );   
    }

    public fun assert_vector_lengths_are_equal(creator: vector<address>,
                                               collection_name: vector<String>,
                                               token_name: vector<String>,
                                               property_version: vector<u64>) {
        // TODO: assert all vector lengths are equal
        let len = vector::length(&creator);
        assert!(
            len == vector::length(&collection_name) &&
            len == vector::length(&token_name) &&
            len == vector::length(&property_version),
            ERROR_VECTOR_LENGTHS_NOT_EQUAL
        );
    }

    //
    // Entry functions
    //
    public entry fun initialize_game(
        account: &signer,
        creator: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        join_amount_requirement: u64
    ) {
        // TODO: run assert_nftango_store_does_not_exist
        let account_address = signer::address_of(account);
        assert_nftango_store_does_not_exist(account_address);

        // TODO: create resource account
        let registry_seed = u128_to_string((timestamp::now_microseconds() as u128));
        string::append(&mut registry_seed, string::utf8(b"nftango_seed"));        
        let (resource_signer, signer_capability) = account::create_resource_account(account, *string::bytes(&registry_seed));
        let resource_account = signer::address_of(&resource_signer);
        // TODO: token::create_token_id_raw
        let token_id = token::create_token_id_raw(creator, collection_name, token_name, property_version);

        // TODO: opt in to direct transfer for resource account
        token::opt_in_direct_transfer(&resource_signer, true);

        // TODO: transfer NFT to resource account
        let token_amount = token::balance_of(account_address, token_id);
        token::transfer(account, token_id, resource_account, token_amount);

        // TODO: move_to resource `NFTangoStore` to account signer

        let opponent_address : Option<address> = option::none();
        let opponent_token_ids = vector::empty<TokenId>();
        move_to(account,  NFTangoStore {
            creator_token_id: token_id,
            join_amount_requirement,
            opponent_address,
            opponent_token_ids,
            active: true,
            has_claimed: false,
            did_creator_win: option::some(false),
            signer_capability
        });
    }

    public entry fun cancel_game(
        account: &signer,
    ) acquires NFTangoStore {
        // TODO: run assert_nftango_store_exists
        let account_address = signer::address_of(account);
        assert_nftango_store_exists(account_address);

        // TODO: run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);

        // TODO: run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(account_address);

        // TODO: opt in to direct transfer for account
        token::opt_in_direct_transfer(account, true);

        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        let resource_signer = account::create_signer_with_capability(&nftango_store.signer_capability);
        let token_id = nftango_store.creator_token_id;
        let join_amount_requirement = nftango_store.join_amount_requirement;
        // TODO: transfer NFT to account address
        token::transfer(&resource_signer, token_id, account_address, join_amount_requirement);

        // TODO: set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public fun join_game(
        account: &signer,
        game_address: address,
        creators: vector<address>,
        collection_names: vector<String>,
        token_names: vector<String>,
        property_versions: vector<u64>,
    ) acquires NFTangoStore {

        // TODO: run assert_vector_lengths_are_equal
        assert_vector_lengths_are_equal(
            creators,
            collection_names,
            token_names,
            property_versions
        );

        // TODO: loop through and create token_ids vector<TokenId>
        let account_address = signer::address_of(account);
        let index = 0;
        let len = vector::length(&creators);
        let opponent_token_ids = vector::empty<TokenId>();
        while (index < len) {
            let creator = *vector::borrow(&creators, index);
            let collection_name = *vector::borrow(&collection_names, index);
            let token_name = *vector::borrow(&token_names, index);
            let property_version = *vector::borrow(&property_versions, index);
            let token_id = token::create_token_id_raw(
                creator, 
                collection_name, 
                token_name, 
                property_version
            );
            //TODO: push only new token id
            if (!vector::contains(&opponent_token_ids, &token_id)) {
                vector::push_back(&mut opponent_token_ids, token_id);

            };
            index = index + 1;
        };

        // TODO: run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);
        // TODO: run assert_nftango_store_is_active
        assert_nftango_store_is_active(game_address);
        // TODO: run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(game_address);
        // TODO: run assert_nftango_store_join_amount_requirement_is_met
        assert_nftango_store_join_amount_requirement_is_met(game_address, account_address, opponent_token_ids);

        // TODO: loop through token_ids and transfer each NFT to the resource account
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        let resource_address = account::get_signer_capability_address(&nftango_store.signer_capability);

        len = vector::length(&opponent_token_ids);
        index = 0;
        while(index < len) {
            let token_id = *vector::borrow(&opponent_token_ids, index);
            let token_amount = token::balance_of(account_address, token_id);
            token::transfer(account, token_id, resource_address, token_amount);
            index = index + 1;
        };
        // TODO: set `NFTangoStore.opponent_address` to account_address
        nftango_store.opponent_address = option::some(account_address);
        // TODO: set `NFTangoStore.opponent_token_ids` to token_ids
        nftango_store.opponent_token_ids = opponent_token_ids;
    }

    public entry fun play_game(account: &signer, did_creator_win: bool) acquires NFTangoStore {
        // TODO: run assert_nftango_store_exists
        let account_address = signer::address_of(account);
        assert_nftango_store_exists(account_address);

        // TODO: run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);

        // TODO: run assert_nftango_store_has_an_opponent
        assert_nftango_store_has_an_opponent(account_address);

        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        // TODO: set `NFTangoStore.did_creator_win` to did_creator_win
        nftango_store.did_creator_win = option::some(did_creator_win);
        // TODO: set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public entry fun claim(account: &signer, game_address: address) acquires NFTangoStore {
        // TODO: run assert_nftango_store_exists
        let account_address = signer::address_of(account);
        assert_nftango_store_exists(game_address);

        // TODO: run assert_nftango_store_is_not_active
        assert_nftango_store_is_not_active(game_address);

        // TODO: run assert_nftango_store_has_not_claimed
        assert_nftango_store_has_not_claimed(game_address);

        // TODO: run assert_nftango_store_is_player
        assert_nftango_store_is_player(account_address, game_address);

        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        let resource_signer = account::create_signer_with_capability(&nftango_store.signer_capability);
        let resource_address = account::get_signer_capability_address(&nftango_store.signer_capability);
        // TODO: if the player won, send them all the NFTs
        let len = vector::length(&nftango_store.opponent_token_ids);
        let index = 0;
        while(index < len) {
            let token_id = *vector::borrow(&nftango_store.opponent_token_ids, index);
            let token_amount = token::balance_of(resource_address, token_id);

            if (nftango_store.did_creator_win == option::some(true)) {
                token::transfer(&resource_signer, token_id, account_address, token_amount);
            } else if (
                nftango_store.did_creator_win == option::some(false) && 
                nftango_store.opponent_address == option::some(account_address)
            ) {
                token::transfer(&resource_signer, token_id, account_address, token_amount);
            };
            index = index + 1;
        };
        // TODO: set `NFTangoStore.has_claimed` to true
        nftango_store.has_claimed = true;
    }
}
