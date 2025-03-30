# authorization_hold.cairo

@storage_var
func authorized_holds(user: felt) -> (amount: felt) {
}

@external
func create_authorization_hold{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(user: felt, amount: felt) {
    authorized_holds.write(user, amount);
    return ();
}

@external
func capture_authorized_funds{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(user: felt, amount: felt) {
    let held_amount = authorized_holds.read(user);
    assert held_amount >= amount;
    
    fund_transfer.transfer(user, contract_address, amount);
    authorized_holds.write(user, held_amount - amount);
    return ();
}
