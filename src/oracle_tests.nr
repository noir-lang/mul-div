//! Differential tests against an independent big-integer reference served by
//! `oracle_server.ts`. Run them with `scripts/run.sh`, which starts the server and
//! runs `nargo test` twice: normally, so the tests exercise the constrained path,
//! and with `--force-brillig`, so they exercise the unconstrained path.
//!
//! The parametric tests take random inputs from the `nargo test` fuzzer. A random
//! input may be one the library rejects; the reference reports that through the
//! `*_ok` flags and the test then checks nothing for that operation. The rejection
//! paths are covered by the fixed `should_fail_with` tests in `tests.nr`.

use crate::MulDiv;
use bigint::{BigInt, U256};

global U128_MAX: u128 = 0xffffffffffffffffffffffffffffffff;

/// Exact results of `a * b / d` from the reference implementation.
/// `rem_ok` is false when `d` is zero or the floor quotient does not fit in the type;
/// `ceil_ok` is false when `d` is zero or the ceiling quotient does not fit.
struct Reference<T> {
    rem_ok: bool,
    q: T,
    r: T,
    ceil_ok: bool,
    ceil: T,
}

#[oracle(mulDivU128)]
unconstrained fn mul_div_u128_oracle(a: u128, b: u128, d: u128) -> Reference<u128> {}

#[oracle(mulDivSmall)]
unconstrained fn mul_div_small_oracle(a: u64, b: u64, d: u64, bits: u32) -> Reference<u64> {}

#[oracle(mulDivU256)]
unconstrained fn mul_div_u256_oracle(a: [u8; 32], b: [u8; 32], d: [u8; 32]) -> Reference<[u8; 32]> {}

unconstrained fn u128_reference(a: u128, b: u128, d: u128) -> Reference<u128> {
    mul_div_u128_oracle(a, b, d)
}

unconstrained fn small_reference(a: u64, b: u64, d: u64, bits: u32) -> Reference<u64> {
    mul_div_small_oracle(a, b, d, bits)
}

unconstrained fn u256_reference(a: U256, b: U256, d: U256) -> Reference<[u8; 32]> {
    mul_div_u256_oracle(a.to_le_bytes(), b.to_le_bytes(), d.to_le_bytes())
}

fn check_u128(a: u128, b: u128, d: u128) -> Reference<u128> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { u128_reference(a, b, d) };
    if expected.rem_ok {
        assert_eq(a.mul_div_rem(b, d), (expected.q, expected.r));
        assert_eq(a.mul_div_floor(b, d), expected.q);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), expected.ceil);
    }
    expected
}

fn check_u256(a: U256, b: U256, d: U256) -> Reference<[u8; 32]> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { u256_reference(a, b, d) };
    if expected.rem_ok {
        let q = U256::from_le_bytes(expected.q);
        let r = U256::from_le_bytes(expected.r);
        assert_eq(a.mul_div_rem(b, d), (q, r));
        assert_eq(a.mul_div_floor(b, d), q);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), U256::from_le_bytes(expected.ceil));
    }
    expected
}

fn u128_max3(a: u128, b: u128, c: u128) -> u128 {
    let ab = if a > b { a } else { b };
    if ab > c {
        ab
    } else {
        c
    }
}

fn u256_max3(a: U256, b: U256, c: U256) -> U256 {
    let ab = if a > b { a } else { b };
    if ab > c {
        ab
    } else {
        c
    }
}

#[test]
fn u128_random(a: u128, b: u128, d: u128) {
    let _ = check_u128(a, b, d);
}

#[test]
fn u128_fitting_quotient(a: u128, b: u128) {
    // a * b / max(a, b) <= min(a, b), usually with a product wider than u128.
    let expected = check_u128(a, b, u128_max3(a, b, 1));
    assert(expected.rem_ok);
}

#[test]
fn u128_exact_division(a: u128, b: u128) {
    let b = u128_max3(b, 1, 1);
    let expected = check_u128(a, b, b);
    assert(expected.rem_ok & (expected.r == 0));
}

#[test]
fn u128_small_divisor(a: u128, s: u64) {
    // a * s / (s + 1) < a always fits; the remainder is usually nonzero.
    let s = s as u128;
    let expected = check_u128(a, s, s + 1);
    assert(expected.rem_ok);
}

#[test]
fn u128_ceiling_overflow(k: u32) {
    // (MAX - k)^2 = MAX * (MAX - 2k) + k^2 with 0 < k^2 < MAX - 2k:
    // the floor quotient is MAX, so only the ceiling overflows.
    let k = k as u128 + 1;
    let expected = check_u128(U128_MAX - k, U128_MAX - k, U128_MAX - 2 * k);
    assert(expected.rem_ok & !expected.ceil_ok);
}

#[test]
fn u256_random(a: [u8; 32], b: [u8; 32], d: [u8; 32]) {
    let _ = check_u256(
        U256::from_le_bytes(a),
        U256::from_le_bytes(b),
        U256::from_le_bytes(d),
    );
}

#[test]
fn u256_fitting_quotient(a: [u8; 32], b: [u8; 32]) {
    let a = U256::from_le_bytes(a);
    let b = U256::from_le_bytes(b);
    let expected = check_u256(a, b, u256_max3(a, b, U256::one()));
    assert(expected.rem_ok);
}

#[test]
fn u256_exact_division(a: [u8; 32], b: [u8; 32]) {
    let a = U256::from_le_bytes(a);
    let b = u256_max3(U256::from_le_bytes(b), U256::one(), U256::one());
    let expected = check_u256(a, b, b);
    assert(expected.rem_ok & (expected.r == [0; 32]));
}

#[test]
fn u256_small_divisor(a: [u8; 32], s: u64) {
    let s = U256::from(s as u128);
    let expected = check_u256(U256::from_le_bytes(a), s, s + U256::one());
    assert(expected.rem_ok);
}

#[test]
fn u256_half_width_divisor(a: [u8; 32], s: u128) {
    // A 128-bit divisor next to the 120-bit limb boundary of U256.
    let s = U256::from(s);
    let expected = check_u256(U256::from_le_bytes(a), s, s + U256::one());
    assert(expected.rem_ok);
}

#[test]
fn u256_ceiling_overflow(k: u64) {
    let max = U256::from_le_bytes([255; 32]);
    let k = U256::from(k as u128) + U256::one();
    let expected = check_u256(max - k, max - k, max - k - k);
    assert(expected.rem_ok & !expected.ceil_ok);
}

fn check_u8(a: u8, b: u8, d: u8) -> Reference<u64> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { small_reference(a as u64, b as u64, d as u64, 8) };
    if expected.rem_ok {
        assert_eq(a.mul_div_rem(b, d), (expected.q as u8, expected.r as u8));
        assert_eq(a.mul_div_floor(b, d), expected.q as u8);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), expected.ceil as u8);
    }
    expected
}

#[test]
fn u8_random(a: u8, b: u8, d: u8) {
    let _ = check_u8(a, b, d);
}

#[test]
fn u8_fitting_quotient(a: u8, b: u8) {
    let ab = if a > b { a } else { b };
    let d = if ab > 1 { ab } else { 1 };
    let expected = check_u8(a, b, d);
    assert(expected.rem_ok);
}

#[test]
fn u8_ceiling_overflow(k: u8) {
    // (MAX - k)^2 = MAX * (MAX - 2k) + k^2 with 0 < k^2 < MAX - 2k for 1 <= k <= 14.
    let k = k % 14 + 1;
    let max: u8 = 0xff;
    let expected = check_u8(max - k, max - k, max - 2 * k);
    assert(expected.rem_ok & !expected.ceil_ok);
}

fn check_u16(a: u16, b: u16, d: u16) -> Reference<u64> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { small_reference(a as u64, b as u64, d as u64, 16) };
    if expected.rem_ok {
        assert_eq(a.mul_div_rem(b, d), (expected.q as u16, expected.r as u16));
        assert_eq(a.mul_div_floor(b, d), expected.q as u16);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), expected.ceil as u16);
    }
    expected
}

#[test]
fn u16_random(a: u16, b: u16, d: u16) {
    let _ = check_u16(a, b, d);
}

#[test]
fn u16_fitting_quotient(a: u16, b: u16) {
    let ab = if a > b { a } else { b };
    let d = if ab > 1 { ab } else { 1 };
    let expected = check_u16(a, b, d);
    assert(expected.rem_ok);
}

#[test]
fn u16_ceiling_overflow(k: u16) {
    // (MAX - k)^2 = MAX * (MAX - 2k) + k^2 with 0 < k^2 < MAX - 2k for 1 <= k <= 254.
    let k = k % 254 + 1;
    let max: u16 = 0xffff;
    let expected = check_u16(max - k, max - k, max - 2 * k);
    assert(expected.rem_ok & !expected.ceil_ok);
}

fn check_u32(a: u32, b: u32, d: u32) -> Reference<u64> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { small_reference(a as u64, b as u64, d as u64, 32) };
    if expected.rem_ok {
        assert_eq(a.mul_div_rem(b, d), (expected.q as u32, expected.r as u32));
        assert_eq(a.mul_div_floor(b, d), expected.q as u32);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), expected.ceil as u32);
    }
    expected
}

#[test]
fn u32_random(a: u32, b: u32, d: u32) {
    let _ = check_u32(a, b, d);
}

#[test]
fn u32_fitting_quotient(a: u32, b: u32) {
    let ab = if a > b { a } else { b };
    let d = if ab > 1 { ab } else { 1 };
    let expected = check_u32(a, b, d);
    assert(expected.rem_ok);
}

#[test]
fn u32_ceiling_overflow(k: u32) {
    // (MAX - k)^2 = MAX * (MAX - 2k) + k^2 with 0 < k^2 < MAX - 2k for 1 <= k <= 65534.
    let k = k % 65534 + 1;
    let max: u32 = 0xffffffff;
    let expected = check_u32(max - k, max - k, max - 2 * k);
    assert(expected.rem_ok & !expected.ceil_ok);
}

fn check_u64(a: u64, b: u64, d: u64) -> Reference<u64> {
    // Safety: the reference is only compared against, never used as a result.
    let expected = unsafe { small_reference(a as u64, b as u64, d as u64, 64) };
    if expected.rem_ok {
        assert_eq(a.mul_div_rem(b, d), (expected.q as u64, expected.r as u64));
        assert_eq(a.mul_div_floor(b, d), expected.q as u64);
    }
    if expected.ceil_ok {
        assert_eq(a.mul_div_ceil(b, d), expected.ceil as u64);
    }
    expected
}

#[test]
fn u64_random(a: u64, b: u64, d: u64) {
    let _ = check_u64(a, b, d);
}

#[test]
fn u64_fitting_quotient(a: u64, b: u64) {
    let ab = if a > b { a } else { b };
    let d = if ab > 1 { ab } else { 1 };
    let expected = check_u64(a, b, d);
    assert(expected.rem_ok);
}

#[test]
fn u64_ceiling_overflow(k: u64) {
    // (MAX - k)^2 = MAX * (MAX - 2k) + k^2 with 0 < k^2 < MAX - 2k for 1 <= k <= 4294967294.
    let k = k % 4294967294 + 1;
    let max: u64 = 0xffffffffffffffff;
    let expected = check_u64(max - k, max - k, max - 2 * k);
    assert(expected.rem_ok & !expected.ceil_ok);
}
