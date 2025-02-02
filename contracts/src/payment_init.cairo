// #[starknet::interface]
// trait ISubscriptionManager<T> {
//     fn subscribe(self: @ContractState, plan_id: u256, duration: u256) -> u256;
//     fn cancel_subscription(self: @ContractState, subscription_id: u256) -> bool;
//     fn check_subscription_status(self: @ContractState, user: ContractAddress) -> bool;
//     fn upgrade_subscription(self: @ContractState, new_plan_id: u256) -> bool;
// }

// #[derive(Drop, Copy, Serialize, Starknet)]
// enum SubscriptionStatus {
//     Active,
//     Cancelled,
//     Expired
// }

// #[derive(Drop, Copy, Serialize, Starknet)]
// struct Subscription {
//     id: u256,
//     plan_id: u256,
//     user: ContractAddress,
//     start_time: u64,
//     end_time: u64,
//     status: SubscriptionStatus
// }

// #[starknet::storage]
// struct Storage {
//     subscriptions: Map<u256, Subscription>,
//     user_subscription: Map<ContractAddress, u256>,
//     subscription_counter: u256,
//     subscription_plans: Map<u256, u256>, // plan_id -> price
// }
