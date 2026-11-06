//! `MulDiv` for unsigned types of at most 64 bits.
//!
//! For these widths the full product fits in a `u128`, so an unconstrained hint
//! computes `(q, r)` with native `u128` division. Returning them as `T` range-checks
//! both to the type's width. The constrained check is then a single `Field` equation
//! `a * b == q * d + r` with `r < d`. Every term is below 2^128, far under the field
//! modulus, so the equation holds over the integers and fixes `(q, r)`.

use crate::MulDiv;
use std::convert::AsPrimitive;

unconstrained fn div_rem_hint<T>(a: T, b: T, d: T, max: T) -> (T, T)
where
    T: AsPrimitive<u128>,
    u128: AsPrimitive<T>,
{
    let d: u128 = d.as_();
    assert(d != 0, "mul_div: zero denominator");
    let a: u128 = a.as_();
    let b: u128 = b.as_();
    let product = a * b;
    let q = product / d;
    let max: u128 = max.as_();
    assert(q <= max, "mul_div: quotient overflow");
    (q.as_(), (product % d).as_())
}

fn mul_div_rem<T>(a: T, b: T, d: T, max: T) -> (T, T)
where
    T: AsPrimitive<u128> + AsPrimitive<Field> + Eq + Ord + From<u8>,
    u128: AsPrimitive<T>,
{
    // Safety: constrained callers check the integer relation and bounds below.
    let (q, r) = unsafe { div_rem_hint(a, b, d, max) };
    if !std::runtime::is_unconstrained() {
        let a_field: Field = a.as_();
        let b_field: Field = b.as_();
        let d_field: Field = d.as_();
        let q_field: Field = q.as_();
        let r_field: Field = r.as_();
        assert(d != T::from(0), "mul_div: zero denominator");
        assert(r < d, "mul_div: remainder out of range");
        assert_eq(a_field * b_field, q_field * d_field + r_field);
    }
    (q, r)
}

fn mul_div_ceil<T>(a: T, b: T, d: T, max: T) -> T
where
    T: AsPrimitive<u128> + AsPrimitive<Field> + Eq + Ord + std::ops::Add + From<u8>,
    u128: AsPrimitive<T>,
{
    let (q, r) = mul_div_rem(a, b, d, max);
    let zero: T = T::from(0);
    if r == zero {
        q
    } else {
        assert(q < max, "mul_div: ceiling overflow");
        q + T::from(1)
    }
}

impl MulDiv for u8 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        mul_div_rem(self, rhs, denominator, 0xff)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        mul_div_ceil(self, rhs, denominator, 0xff)
    }
}

impl MulDiv for u16 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        mul_div_rem(self, rhs, denominator, 0xffff)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        mul_div_ceil(self, rhs, denominator, 0xffff)
    }
}

impl MulDiv for u32 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        mul_div_rem(self, rhs, denominator, 0xffffffff)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        mul_div_ceil(self, rhs, denominator, 0xffffffff)
    }
}

impl MulDiv for u64 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        mul_div_rem(self, rhs, denominator, 0xffffffffffffffff)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        mul_div_ceil(self, rhs, denominator, 0xffffffffffffffff)
    }
}
