use starknet::{ContractAddress};
#[starknet::interface]
pub trait IFundTransfer<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256 );
    fn transfer_erc20(ref self: TContractState, recipient: ContractAddress, amount: u256 );
    fn get_balance(self: @TContractState, address: ContractAddress) -> u256;
    fn get_balance_erc20(self: @TContractState, address: ContractAddress) -> u256;
}



#[starknet::contract]
pub mod FundTransfer{
    use core::num::traits::Zero;
    use starknet::event::EventEmitter;
    use super::IFundTransfer;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};

    use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};


    #[storage]
    struct Storage {
        native_token_contract: ContractAddress,
        balances: Map<ContractAddress, u256>
    }

    pub mod Errors{
        pub const INSUFFICIENT_BALANCE: felt252 = 'Caller balance is insufficient';
        pub const CANNOT_TRANSFER_BALANCE: felt252 = 'Transfer not allowed by caller';
        pub const ZERO_ADDRESS_RECEIVER: felt252 = 'Cannot transfer to zero address';
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FundTransferEvent: FundTransferEvent
    }


    #[derive(Drop, starknet::Event)]
    struct FundTransferEvent{
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        date: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState, native_token: ContractAddress){
        self.native_token_contract.write(native_token);
    }
    
    #[abi(embed_v0)]
    impl FundTransfermpl of IFundTransfer<ContractState> {
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256 ){
            // verify that recipient is not a zero address
            assert(!recipient.is_zero(), Errors::ZERO_ADDRESS_RECEIVER);

            let caller = get_caller_address();
            let balance = self.balances.entry(caller).read();
            assert(balance >= amount, Errors::INSUFFICIENT_BALANCE);
            
            // remove funds from sender
            self.balances.entry(caller).write(balance - amount);
            // add funds to recipient
            self.balances.entry(recipient).write(
                self.balances.entry(recipient).read() + amount
            );
            // emit funds transfer event
            self.emit(
                FundTransferEvent{
                    sender: caller,
                    recipient,
                    amount,
                    date: get_block_timestamp()

                }
            )
        }
        fn transfer_erc20(ref self: ContractState, recipient: ContractAddress, amount: u256 ){
            // verify that recipient is not a zero address
            assert(!recipient.is_zero(), Errors::ZERO_ADDRESS_RECEIVER);

            let caller = get_caller_address();
            let erc_dispatcher = ERC20ABIDispatcher {contract_address: self.native_token_contract.read()};

            // check token balance
            assert(erc_dispatcher.balance_of(caller) >= amount, Errors::INSUFFICIENT_BALANCE);
            
            // check erc20 allowance
            let allowance = erc_dispatcher.allowance(caller, get_contract_address());
            assert(allowance >= amount, Errors::CANNOT_TRANSFER_BALANCE);

            // transfer amount to recipient
            erc_dispatcher.transfer_from(caller, recipient, amount);

            // emit funds transfer event
            self.emit(
                FundTransferEvent{
                    sender: caller,
                    recipient,
                    amount,
                    date: get_block_timestamp()

                }
            )

        }
        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            self.balances.entry(address).read()
        }
        fn get_balance_erc20(self: @ContractState, address: ContractAddress) -> u256 {
            let erc_dispatcher = ERC20ABIDispatcher {contract_address: self.native_token_contract.read()};
            erc_dispatcher.balance_of(address)
        }
    }
}