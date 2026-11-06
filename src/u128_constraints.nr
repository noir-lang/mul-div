use bigint::{evaluate_quadratic_expression, U256};

/// Check the unique Euclidean quotient/remainder over integers, not just in Field.
/// Native u128 parameters and the unconstrained call boundary enforce width bounds;
/// U256 conversion and bigint's expression verifier also range-check their limbs.
pub(crate) fn verify_division(a: u128, b: u128, d: u128, q: u128, r: u128) {
    assert(d != 0, "mul_div: zero denominator");
    assert(r < d, "mul_div: remainder out of range");
    // a*b - q*d - r = 0. Bigint enforces the complete integer relation using
    // bounded limbs/carries, so multiples of the field modulus cannot disappear.
    evaluate_quadratic_expression(
        [[U256::from(a)], [U256::from(q)]],
        [[false], [true]],
        [[U256::from(b)], [U256::from(d)]],
        [[false], [false]],
        [U256::from(r)],
        [true],
    );
}

// Exercise the constraint boundary with supplied values, not the honest generator.
// as_witness prevents the invalid equations from being rejected by constant folding.
#[test]
fn accepts_supplied_wide_witness() {
    check_supplied([
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        0,
    ]);
}

#[test]
fn accepts_supplied_inexact_witness() {
    check_supplied([7, 9, 4, 15, 3]);
}

#[test(should_fail)]
fn rejects_wrong_quotient() {
    check_supplied([7, 9, 4, 16, 3]);
}

#[test(should_fail)]
fn rejects_wrong_remainder() {
    check_supplied([7, 9, 4, 15, 2]);
}

#[test(should_fail_with = "mul_div: remainder out of range")]
fn rejects_noncanonical_remainder() {
    // The integer relation holds, but this is not the floor quotient.
    check_supplied([7, 9, 4, 14, 7]);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn rejects_zero_denominator_even_with_zero_product() {
    check_supplied([0, 9, 0, 0, 0]);
}

#[test(should_fail)]
fn rejects_wrapped_quotient_for_overflowing_result() {
    // The true quotient is 2^128. Even if narrowing wraps it to zero, the
    // constrained integer relation must reject the resulting u128 candidate.
    check_supplied([
        0x10000000000000000,
        0x10000000000000000,
        1,
        0x100000000000000000000000000000000,
        0,
    ]);
}

fn check_supplied(values: [Field; 5]) {
    for value in values {
        std::as_witness(value);
    }
    verify_division(
        values[0] as u128,
        values[1] as u128,
        values[2] as u128,
        values[3] as u128,
        values[4] as u128,
    );
}

#[test(should_fail)]
fn rejects_field_congruent_but_integer_wrong_witness() {
    // MAX^2 - q*MAX - r = 5*p for the BN254 scalar modulus p.
    // Both q/r fit u128 and r < MAX. A single Field equation would accept this.
    check_supplied([
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        18663543855022578254064320005638014508,
        91752719614413399769914463894048949800,
    ]);
}
