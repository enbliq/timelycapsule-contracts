#[starknet::contract]
mod PaymentIntent {
    use starknet::{ContractAddress, get_caller_address};

    #[derive(Drop, starknet::Store, Serde)]
    struct PaymentIntentData {
        amount: u256,
        currency: felt252,
        customer: ContractAddress,
        recipient: ContractAddress,
        status: felt252,
    }

    #[storage]
    struct Storage {
        intents: LegacyMap<felt252, PaymentIntentData>,
        next_intent_id: u128,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        IntentCreated: IntentCreated,
    }

    #[derive(Drop, starknet::Event, Serde)]
    struct IntentCreated {
        intent_id: felt252,
        customer: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        currency: felt252,
    }

    #[external(v0)]
    impl PaymentIntentImpl of super::PaymentIntentInterface {
        fn create_intent(
            ref self: ContractState,
            amount: u256,
            currency: felt252,
            customer: ContractAddress,
            recipient: ContractAddress,
        ) -> felt252 {
            let mut storage = self.storage();
            let intent_id = storage.next_intent_id.read();

            let payment_intent = PaymentIntentData {
                amount,
                currency,
                customer,
                recipient,
                status: 'created',
            };

            storage.intents.write(intent_id.into(), payment_intent);
            storage.next_intent_id.write(intent_id + 1);

            self.emit(
                IntentCreated {
                    intent_id: intent_id.into(),
                    customer,
                    recipient,
                    amount,
                    currency,
                },
            );

            intent_id.into()
        }

        #[view]
        fn get_intent(self: @ContractState, intent_id: felt252) -> PaymentIntentData {
            self.storage().intents.read(intent_id)
        }
    }
}
