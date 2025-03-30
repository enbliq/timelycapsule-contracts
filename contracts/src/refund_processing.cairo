
@storage_var
func payment_status(payment_id: felt) -> (status: felt) {
}

@external
func process_refund{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(payment_id: felt, recipient: felt, amount: felt) {
    let current_status = payment_status.read(payment_id);
    assert current_status == 1;  // Verify payment was successful
    
    fund_transfer.transfer(contract_address, recipient, amount);
    payment_status.write(payment_id, 3);  // 3 = refunded status
    return ();
}