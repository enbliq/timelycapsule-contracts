use core::starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
struct Subscription {
    subscriber: ContractAddress,
    tier: u32,
    start_time: u64,
    end_time: u64,
    active: bool,
}

#[starknet::interface]
trait ISubscriptionManager<T> {
    fn get_subscription(self: @T, user: ContractAddress) -> Subscription;
    fn is_subscribed(self: @T, user: ContractAddress) -> bool;
    fn get_tier_price(self: @T, tier: u32) -> u256;
    fn subscribe(ref self: T, tier: u32);
    fn cancel_subscription(ref self: T);
    fn update_tier_price(ref self: T, tier: u32, new_price: u256);
}

#[starknet::contract]
mod SubscriptionManager {
    use core::starknet::ContractAddress;
    use core::starknet::get_caller_address;
    use core::starknet::get_block_timestamp;
    use core::starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use super::Subscription;

    const FREE_TIER: u32 = 0;
    const PRO_TIER: u32 = 1;
    const SUBSCRIPTION_DURATION: u64 = 2592000; // 30 days in seconds

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SubscriptionCreated: SubscriptionCreated,
        SubscriptionCancelled: SubscriptionCancelled,
        TierPriceUpdated: TierPriceUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct SubscriptionCreated {
        user: ContractAddress,
        tier: u32,
        start_time: u64,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct SubscriptionCancelled {
        user: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct TierPriceUpdated {
        tier: u32,
        new_price: u256,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        subscriptions: Map::<ContractAddress, Subscription>,
        tier_prices: Map::<u32, u256>,
        is_active: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
        self.owner.write(caller);
        self.is_active.write(true);
        
        // Initialize tier prices
        self.tier_prices.write(FREE_TIER, 0);
        self.tier_prices.write(PRO_TIER, 1000000000000000000); // 1 ETH equivalent
    }

    #[abi(embed_v0)]
    impl SubscriptionManagerImpl of super::ISubscriptionManager<ContractState> {
        fn get_subscription(self: @ContractState, user: ContractAddress) -> Subscription {
            self.subscriptions.read(user)
        }

        fn is_subscribed(self: @ContractState, user: ContractAddress) -> bool {
            let subscription = self.subscriptions.read(user);
            let current_time = get_block_timestamp();
            subscription.active && current_time <= subscription.end_time
        }

        fn get_tier_price(self: @ContractState, tier: u32) -> u256 {
            self.tier_prices.read(tier)
        }

        fn subscribe(ref self: ContractState, tier: u32) {
            assert(self.is_active.read(), 'CONTRACT_NOT_ACTIVE');
            assert(tier <= PRO_TIER, 'INVALID_TIER');

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Check payment for Pro tier
            if tier == PRO_TIER {
                let _price = self.tier_prices.read(PRO_TIER);
                // Payment verification would go here
            }

            let subscription = Subscription {
                subscriber: caller,
                tier,
                start_time: current_time,
                end_time: current_time + SUBSCRIPTION_DURATION,
                active: true,
            };

            self.subscriptions.write(caller, subscription);

            // Emit subscription created event
            self.emit(Event::SubscriptionCreated(SubscriptionCreated {
                user: caller,
                tier,
                start_time: current_time,
                end_time: current_time + SUBSCRIPTION_DURATION,
            }));
        }

        fn cancel_subscription(ref self: ContractState) {
            let caller = get_caller_address();
            let mut subscription = self.subscriptions.read(caller);
            assert(subscription.active, 'NO_ACTIVE_SUBSCRIPTION');

            subscription.active = false;
            self.subscriptions.write(caller, subscription);

            // Emit subscription cancelled event
            self.emit(Event::SubscriptionCancelled(SubscriptionCancelled { user: caller }));
        }

        fn update_tier_price(ref self: ContractState, tier: u32, new_price: u256) {
            self.assert_only_owner();
            assert(tier <= PRO_TIER, 'INVALID_TIER');

            self.tier_prices.write(tier, new_price);

            // Emit tier price updated event
            self.emit(Event::TierPriceUpdated(TierPriceUpdated {
                tier,
                new_price,
            }));
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'CALLER_NOT_OWNER');
        }
    }
}