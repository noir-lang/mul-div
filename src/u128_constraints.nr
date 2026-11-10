/// Check the unique Euclidean quotient/remainder over the integers, not just in Field.
///
/// With every operand below 2^128, D = a*b - q*d - r satisfies |D| < 2^257. The
/// relation is checked modulo the field modulus p (one native Field equation) and
/// modulo 2^14 (on the low 14-bit limbs). Since p is odd, D is then a multiple of
/// 2^14 * p, which exceeds 2^257 for any field of at least 244 bits, so D = 0.
pub(crate) fn verify_division(a: u128, b: u128, d: u128, q: u128, r: u128) {
    assert(std::field::modulus_num_bits() >= 244);
    assert(d != 0, "mul_div: zero denominator");
    assert(r < d, "mul_div: remainder out of range");

    assert_eq((a as Field) * (b as Field), (q as Field) * (d as Field) + (r as Field));

    // Low-limb residue: t = a0*b0 - q0*d0 - r0 lies in (-2^29, 2^28), so
    // t + 2^29 is in (0, 2^30) and must equal 2^14 * m with m < 2^16.
    let values = [a as Field, b as Field, q as Field, d as Field, r as Field];
    // Safety: each split is constrained below to x = 2^14 * hi + lo with lo < 2^14
    // and hi < 2^114, which fixes lo = x mod 2^14 for x < 2^128.
    let (high, low) = unsafe { split_low_limbs(values) };
    for i in 0..5 {
        low[i].assert_max_bit_size::<14>();
        high[i].assert_max_bit_size::<114>();
        assert_eq(values[i], high[i] * 0x4000 + low[i]);
    }
    let t = low[0] * low[1] - low[2] * low[3] - low[4];
    let m = (t + 0x20000000) / 0x4000;
    m.assert_max_bit_size::<16>();
}

unconstrained fn split_low_limbs(values: [Field; 5]) -> ([Field; 5], [Field; 5]) {
    let mut high = [0; 5];
    let mut low = [0; 5];
    for i in 0..5 {
        let x = values[i] as u128;
        high[i] = (x >> 14) as Field;
        low[i] = (x & 0x3fff) as Field;
    }
    (high, low)
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

#[test(should_fail)]
fn rejects_limb_congruent_but_field_wrong_witness() {
    // 7*9 - 4111*4 - 3 = -16384, a multiple of 2^14 that the Field equation rejects.
    check_supplied([7, 9, 4, 4111, 3]);
}
