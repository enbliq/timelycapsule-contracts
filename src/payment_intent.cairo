%lang starknet

use core::array::ArrayTrait;
use core::integer::u256;
use core::string::string;
use core::{bool, felt252};

use starknet::storage::{Storage, storage_map};
use starknet::{ContractAddress, contract};
use starknet::short_string::short_string;


#[derive(Copy, Drop, Serde)]
struct PaymentIntentData {
    amount: u256,
    currency: felt252,
    customer: ContractAddress,
    recipient: ContractAddress,
    status: felt252,
}


#[contract]
mod PaymentIntent {
    use super::*;

    #[storage]
    struct Storage {
        intent_counter: felt252,
        intents: LegacyMap<felt252, PaymentIntentData>,
    }

    
    #[external]
    fn create_intent(
        ref self: ContractState,
        amount: u256,
        currency: felt252,
        customer: ContractAddress,
        recipient: ContractAddress,
    ) {
        let id = self.intent_counter.read();
        let new_id = id + 1;
        self.intent_counter.write(new_id);

        let status = short_string!("created"); // Convert "created" to felt252

        let intent = PaymentIntentData {
            amount,
            currency,
            customer,
            recipient,
            status,
        };

        self.intents.write(new_id, intent);
    }

   
    #[view]
    fn get_intent(self: @ContractState, intent_id: felt252) -> PaymentIntentData {
        self.intents.read(intent_id)
    }
}
