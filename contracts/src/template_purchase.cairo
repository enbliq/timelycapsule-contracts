use core::starknet::ContractAddress;
use core::starknet::get_caller_address;
use core::starknet::get_block_timestamp;

#[derive(Drop, Serde, starknet::Store)]
struct TemplatePurchase {
    buyer: ContractAddress,
    template_id: u32, // Unique ID for each template
    purchase_time: u64,
}

#[starknet::interface]
trait ITemplatePurchase<T> {
    fn get_purchase(self: @T, buyer: ContractAddress, template_id: u32) -> TemplatePurchase;
    fn has_purchased_template(self: @T, buyer: ContractAddress, template_id: u32) -> bool;
    fn get_template_price(self: @T, template_id: u32) -> u256;
    fn purchase_template(ref self: T, template_id: u32);
}

#[starknet::contract]
mod TemplatePurchaseContract {
    use super::{ContractAddress, TemplatePurchase, ITemplatePurchase};
    use core::starknet::get_caller_address;
    use core::starknet::get_block_timestamp;
    use core::starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess,};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TemplatePurchased: TemplatePurchased,
    }

    #[derive(Drop, starknet::Event)]
    struct TemplatePurchased {
        buyer: ContractAddress,
        template_id: u32,
        purchase_time: u64,
    }

    #[storage]
    struct Storage {
        template_prices: Map<u32, u256>, // Maps template IDs to their prices
        purchases: Map<
            (ContractAddress, u32), TemplatePurchase
        >, // Maps (buyer, template_id) to purchase details
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize prices for templates (example)
        self.template_prices.write(1, 1000); // Template ID 1, price 1000
        self.template_prices.write(2, 2000); // Template ID 2, price 2000
    }

    #[abi(embed_v0)]
    impl TemplatePurchaseImpl of ITemplatePurchase<ContractState> {
        fn get_purchase(
            self: @ContractState, buyer: ContractAddress, template_id: u32
        ) -> TemplatePurchase {
            self.purchases.read((buyer, template_id))
        }

        fn has_purchased_template(
            self: @ContractState, buyer: ContractAddress, template_id: u32
        ) -> bool {
            self.purchases.read((buyer, template_id)).buyer != ContractAddress::default()
        }

        fn get_template_price(self: @ContractState, template_id: u32) -> u256 {
            self.template_prices.read(template_id)
        }

        fn purchase_template(ref self: ContractState, template_id: u32) {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            // Ensure the template exists
            let price = self.template_prices.read(template_id);
            assert(price != 0, 'INVALID_TEMPLATE_ID');

            // Ensure the caller hasn't already purchased this template
            assert(!self.has_purchased_template(caller, template_id), 'ALREADY_PURCHASED');

            // Ensure the caller sent enough ETH (payment logic would go here)
            // Payment verification would go here

            // Record the purchase
            let purchase = TemplatePurchase {
                buyer: caller, template_id, purchase_time: current_time,
            };
            self.purchases.write((caller, template_id), purchase);

            // Emit an event
            self
                .emit(
                    Event::TemplatePurchased(
                        TemplatePurchased {
                            buyer: caller, template_id, purchase_time: current_time,
                        }
                    )
                );
        }
    }
}
