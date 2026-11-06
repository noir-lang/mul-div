use crate::MulDiv;
use bigint::U256;

#[export]
fn bench_u128_mul_div_floor(a: u128, b: u128, d: u128) -> u128 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u128_mul_div_rem(a: u128, b: u128, d: u128) -> (u128, u128) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u128_mul_div_ceil(a: u128, b: u128, d: u128) -> u128 {
    a.mul_div_ceil(b, d)
}

#[export]
fn bench_u256_mul_div_floor(a: U256, b: U256, d: U256) -> U256 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u256_mul_div_rem(a: U256, b: U256, d: U256) -> (U256, U256) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u256_mul_div_ceil(a: U256, b: U256, d: U256) -> U256 {
    a.mul_div_ceil(b, d)
}
