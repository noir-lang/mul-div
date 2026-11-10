// Width of the low limbs used for the mod 2^LIMB_BITS check. 14 bits reuses the
// range-check table that every u128 value already needs, so the extra range checks
// add no new table.
global LIMB_BITS: u32 = 14;
// Upper limbs are below 2^HIGH_BITS, so `LIMB * high + low` stays below 2^128 and
// cannot wrap the field.
global HIGH_BITS: u32 = 128 - LIMB_BITS;
global LIMB: Field = 0x4000; // 2^LIMB_BITS
// The low-limb residue t = a0*b0 - q0*d0 - r0 lies in [-(2^28 - 2^14), (2^14 - 1)^2].
// RESIDUE_OFFSET is a multiple of LIMB at least as large as the lower bound's magnitude,
// so t + RESIDUE_OFFSET lies in [0, 2^30).
global RESIDUE_OFFSET: Field = 0x20000000; // 2^29
// (t + RESIDUE_OFFSET) / LIMB in the field is below 2^RESIDUE_QUOTIENT_BITS exactly when
// LIMB divides t: both `LIMB * m` and `t + RESIDUE_OFFSET` are then integers below 2^30.
global RESIDUE_QUOTIENT_BITS: u32 = 16;

/// Check the unique Euclidean quotient/remainder over the integers, not just in Field.
///
/// With every operand below 2^128, D = a*b - q*d - r satisfies |D| < 2^257. The
/// relation is checked modulo the field modulus p (one native Field equation) and
/// modulo 2^LIMB_BITS (on the low limbs). Since p is odd, D is then a multiple of
/// 2^LIMB_BITS * p, which exceeds 2^257 for any field of at least 244 bits, so D = 0.
pub(crate) fn verify_division(a: u128, b: u128, d: u128, q: u128, r: u128) {
    std::static_assert(
        std::field::modulus_num_bits() >= 244,
        "mul_div: the u128 verifier needs a field of at least 244 bits",
    );
    assert(d != 0, "mul_div: zero denominator");
    assert(r < d, "mul_div: remainder out of range");

    assert_eq(
        (a as Field) * (b as Field),
        (q as Field) * (d as Field) + (r as Field),
        "mul_div: product mismatch modulo the field",
    );

    let values = [a as Field, b as Field, q as Field, d as Field, r as Field];
    // Safety: verify_low_limb_residue constrains each split to the unique one with
    // the bounds above, so the hint's values are not trusted.
    let (high, low) = unsafe { split_low_limbs(values) };
    verify_low_limb_residue(values, high, low);
}

/// Checks `a*b - q*d - r = 0 (mod 2^LIMB_BITS)` for `values = [a, b, q, d, r]`, given
/// each value split as `value = LIMB * high + low`. The bounds `low < 2^LIMB_BITS` and
/// `high < 2^HIGH_BITS` make the split unique, so `low = value mod 2^LIMB_BITS`.
fn verify_low_limb_residue(values: [Field; 5], high: [Field; 5], low: [Field; 5]) {
    for i in 0..5 {
        low[i].assert_max_bit_size::<LIMB_BITS>();
        high[i].assert_max_bit_size::<HIGH_BITS>();
        assert_eq(values[i], LIMB * high[i] + low[i], "mul_div: invalid limb split");
    }
    let t = low[0] * low[1] - low[2] * low[3] - low[4];
    let m = (t + RESIDUE_OFFSET) / LIMB;
    m.assert_max_bit_size::<RESIDUE_QUOTIENT_BITS>();
}

unconstrained fn split_low_limbs(values: [Field; 5]) -> ([Field; 5], [Field; 5]) {
    let limb = LIMB as u128;
    let mut high = [0; 5];
    let mut low = [0; 5];
    for i in 0..5 {
        let x = values[i] as u128;
        high[i] = (x / limb) as Field;
        low[i] = (x % limb) as Field;
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

#[test(should_fail_with = "mul_div: product mismatch modulo the field")]
fn rejects_wrong_quotient() {
    check_supplied([7, 9, 4, 16, 3]);
}

#[test(should_fail_with = "mul_div: product mismatch modulo the field")]
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

#[test(should_fail_with = "mul_div: product mismatch modulo the field")]
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

// assert_max_bit_size failures carry this message; here it comes from the residue
// quotient check, because the honest limb split satisfies the split bounds.
#[test(should_fail_with = "call to assert_max_bit_size")]
fn rejects_field_congruent_but_integer_wrong_witness() {
    // MAX^2 - q*MAX - r = 5*p for the BN254 scalar modulus p.
    // Both q/r fit u128 and r < MAX. A single Field equation would accept this,
    // and the low-limb residue is 5 (mod 2^14) because p = 1 (mod 2^28).
    check_supplied([
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff,
        18663543855022578254064320005638014508,
        91752719614413399769914463894048949800,
    ]);
}

#[test(should_fail_with = "mul_div: product mismatch modulo the field")]
fn rejects_limb_congruent_but_field_wrong_witness() {
    // 7*9 - 4111*4 - 3 = -16384, a multiple of 2^14 that the Field equation rejects.
    check_supplied([7, 9, 4, 4111, 3]);
}

// The tests below supply dishonest limb splits to the residue check directly.
// values = [a, b, q, d, r] = [7, 9, 15, 4, 3] is a correct division; every field
// is a single low limb, so the honest split has high = 0.

#[test]
fn residue_accepts_honest_split() {
    check_residue([7, 9, 15, 4, 3], [0; 5], [7, 9, 15, 4, 3]);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn residue_rejects_low_limb_out_of_range() {
    // 7 = LIMB * (-1) + (LIMB + 7): recombines, but low is 2^14 + 7 and high wraps.
    check_residue([7, 9, 15, 4, 3], [-1, 0, 0, 0, 0], [LIMB + 7, 9, 15, 4, 3]);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn residue_rejects_wrong_low_limb_with_field_consistent_high() {
    // The attack the split bounds stop: pick low = 8 and solve high = (7 - 8) / LIMB in
    // the field. It recombines exactly, but high is a huge field element.
    check_residue([7, 9, 15, 4, 3], [-1 / LIMB, 0, 0, 0, 0], [8, 9, 15, 4, 3]);
}

#[test(should_fail_with = "mul_div: invalid limb split")]
fn residue_rejects_split_that_does_not_recombine() {
    check_residue([7, 9, 15, 4, 3], [0; 5], [8, 9, 15, 4, 3]);
}

fn check_residue(values: [Field; 5], high: [Field; 5], low: [Field; 5]) {
    for i in 0..5 {
        std::as_witness(values[i]);
        std::as_witness(high[i]);
        std::as_witness(low[i]);
    }
    verify_low_limb_residue(values, high, low);
}
