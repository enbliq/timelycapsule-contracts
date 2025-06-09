use starknet::contract;
use starknet::ContractAddress;
use starknet::storage::{Storage, storage_map};
use core::bool;
use core::integer::u256;
use core::string::string;
use core::array::ArrayTrait;
use core::felt252;

#[derive(Copy, Drop, Serde)]
struct PaymentIntentData {
    amount: u256,
    currency: felt252,         
    customer: ContractAddress,
    recipient: ContractAddress,
    status: felt252            }

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

        let intent = PaymentIntentData {
            amount,
            currency,
            customer,
            recipient,
            status: 'created'
        };

        self.intents.write(new_id, intent);
    }

    #[view]
    fn get_intent(self: @ContractState, intent_id: felt252) -> PaymentIntentData {
        self.intents.read(intent_id)
    }
}
