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

#[export]
fn bench_u8_mul_div_floor(a: u8, b: u8, d: u8) -> u8 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u8_mul_div_rem(a: u8, b: u8, d: u8) -> (u8, u8) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u8_mul_div_ceil(a: u8, b: u8, d: u8) -> u8 {
    a.mul_div_ceil(b, d)
}

#[export]
fn bench_u16_mul_div_floor(a: u16, b: u16, d: u16) -> u16 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u16_mul_div_rem(a: u16, b: u16, d: u16) -> (u16, u16) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u16_mul_div_ceil(a: u16, b: u16, d: u16) -> u16 {
    a.mul_div_ceil(b, d)
}

#[export]
fn bench_u32_mul_div_floor(a: u32, b: u32, d: u32) -> u32 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u32_mul_div_rem(a: u32, b: u32, d: u32) -> (u32, u32) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u32_mul_div_ceil(a: u32, b: u32, d: u32) -> u32 {
    a.mul_div_ceil(b, d)
}

#[export]
fn bench_u64_mul_div_floor(a: u64, b: u64, d: u64) -> u64 {
    a.mul_div_floor(b, d)
}

#[export]
fn bench_u64_mul_div_rem(a: u64, b: u64, d: u64) -> (u64, u64) {
    a.mul_div_rem(b, d)
}

#[export]
fn bench_u64_mul_div_ceil(a: u64, b: u64, d: u64) -> u64 {
    a.mul_div_ceil(b, d)
}
