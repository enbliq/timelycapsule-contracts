# payment_retry.cairo

@storage_var
func payment_attempts(payment_id: felt) -> (attempts: felt) {
}

@external
func retry_failed_payment{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(payment_id: felt, max_retries: felt) {
    let attempts = payment_attempts.read(payment_id);
    assert attempts < max_retries;
    
    payment_attempts.write(payment_id, attempts + 1);
    return ();
}