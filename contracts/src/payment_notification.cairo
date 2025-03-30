
@event
func payment_event(
    from: felt,
    to: felt,
    amount: felt,
    timestamp: felt,
    payment_id: felt
) {
}

@external
func send_notification{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(from: felt, to: felt, amount: felt, payment_id: felt) {
    let timestamp = get_block_timestamp();
    payment_event.emit(from, to, amount, timestamp, payment_id);
    return ();
}
