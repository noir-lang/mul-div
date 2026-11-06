//! `MulDiv` for unsigned types of at most 64 bits.
//!
//! For these widths the full product fits in a `u128`, so an unconstrained hint
//! computes `(q, r)` with native `u128` division. Returning them as `Self` range-
//! checks both to the type's width. The constrained check is then a single `Field`
//! equation `a * b == q * d + r` with `r < d`. Every term is below 2^128, far under
//! the field modulus, so the equation holds over the integers and fixes `(q, r)`.

use crate::MulDiv;

unconstrained fn u8_div_rem(a: u8, b: u8, d: u8) -> (u8, u8) {
    assert(d != 0, "mul_div: zero denominator");
    let product = (a as u128) * (b as u128);
    let q = product / (d as u128);
    assert(q <= 0xff, "mul_div: quotient overflow");
    (q as u8, (product % (d as u128)) as u8)
}

impl MulDiv for u8 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // Safety: constrained callers check the integer relation and bounds below.
        let (q, r) = unsafe { u8_div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            assert(denominator != 0, "mul_div: zero denominator");
            assert(r < denominator, "mul_div: remainder out of range");
            assert_eq(
                (self as Field) * (rhs as Field),
                (q as Field) * (denominator as Field) + (r as Field),
            );
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == 0 {
            q
        } else {
            assert(q < 0xff, "mul_div: ceiling overflow");
            q + 1
        }
    }
}

unconstrained fn u16_div_rem(a: u16, b: u16, d: u16) -> (u16, u16) {
    assert(d != 0, "mul_div: zero denominator");
    let product = (a as u128) * (b as u128);
    let q = product / (d as u128);
    assert(q <= 0xffff, "mul_div: quotient overflow");
    (q as u16, (product % (d as u128)) as u16)
}

impl MulDiv for u16 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // Safety: constrained callers check the integer relation and bounds below.
        let (q, r) = unsafe { u16_div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            assert(denominator != 0, "mul_div: zero denominator");
            assert(r < denominator, "mul_div: remainder out of range");
            assert_eq(
                (self as Field) * (rhs as Field),
                (q as Field) * (denominator as Field) + (r as Field),
            );
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == 0 {
            q
        } else {
            assert(q < 0xffff, "mul_div: ceiling overflow");
            q + 1
        }
    }
}

unconstrained fn u32_div_rem(a: u32, b: u32, d: u32) -> (u32, u32) {
    assert(d != 0, "mul_div: zero denominator");
    let product = (a as u128) * (b as u128);
    let q = product / (d as u128);
    assert(q <= 0xffffffff, "mul_div: quotient overflow");
    (q as u32, (product % (d as u128)) as u32)
}

impl MulDiv for u32 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // Safety: constrained callers check the integer relation and bounds below.
        let (q, r) = unsafe { u32_div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            assert(denominator != 0, "mul_div: zero denominator");
            assert(r < denominator, "mul_div: remainder out of range");
            assert_eq(
                (self as Field) * (rhs as Field),
                (q as Field) * (denominator as Field) + (r as Field),
            );
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == 0 {
            q
        } else {
            assert(q < 0xffffffff, "mul_div: ceiling overflow");
            q + 1
        }
    }
}

unconstrained fn u64_div_rem(a: u64, b: u64, d: u64) -> (u64, u64) {
    assert(d != 0, "mul_div: zero denominator");
    let product = (a as u128) * (b as u128);
    let q = product / (d as u128);
    assert(q <= 0xffffffffffffffff, "mul_div: quotient overflow");
    (q as u64, (product % (d as u128)) as u64)
}

impl MulDiv for u64 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // Safety: constrained callers check the integer relation and bounds below.
        let (q, r) = unsafe { u64_div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            assert(denominator != 0, "mul_div: zero denominator");
            assert(r < denominator, "mul_div: remainder out of range");
            assert_eq(
                (self as Field) * (rhs as Field),
                (q as Field) * (denominator as Field) + (r as Field),
            );
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == 0 {
            q
        } else {
            assert(q < 0xffffffffffffffff, "mul_div: ceiling overflow");
            q + 1
        }
    }
}
