use bigint::{BigInt, U256};

mod small_integers;
mod u128_division;
mod u128_constraints;
mod u256_constraints;
mod u256_division;

mod benchmarks;
mod oracle_tests;
mod tests;

/// Exact multiply-divide with an intermediate twice the operand width.
/// Rejects zero denominators and results outside Self; never wraps or saturates.
pub trait MulDiv {
    /// Returns the floor quotient and remainder `(q, r)` of `self * rhs / denominator`.
    /// Preserves the full intermediate product, so over the integers
    /// `self * rhs = q * denominator + r` and `0 <= r < denominator`.
    /// Fails if `denominator` is zero or `q` does not fit in `Self`.
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self);

    /// Returns `floor(self * rhs / denominator)`, rounding toward zero.
    /// Preserves the full intermediate product even when it exceeds `Self`.
    /// Fails if `denominator` is zero or the quotient does not fit in `Self`.
    fn mul_div_floor(self, rhs: Self, denominator: Self) -> Self {
        self.mul_div_rem(rhs, denominator).0
    }

    /// Returns `ceil(self * rhs / denominator)`, rounding upward.
    /// Preserves the full intermediate product. Exact divisions match floor;
    /// a nonzero remainder increments the floor quotient by one.
    /// Fails if `denominator` is zero or the rounded quotient does not fit in `Self`,
    /// including when the floor quotient fits but the final increment overflows.
    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self;
}

impl MulDiv for u128 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // Safety: constrained callers verify the exact integer relation and bounds
        // below. The unconstrained helper's assertions are not trusted as constraints.
        let (q, r) = unsafe { u128_division::div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            u128_constraints::verify_division(self, rhs, denominator, q, r);
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == 0 {
            q
        } else {
            assert(q < 0xffffffffffffffffffffffffffffffff, "mul_div: ceiling overflow");
            q + 1
        }
    }
}

impl MulDiv for U256 {
    fn mul_div_rem(self, rhs: Self, denominator: Self) -> (Self, Self) {
        // The helper interprets 120/120/16-bit limbs, so validate input encoding
        // before splitting it into 64-bit digits in either execution context.
        self.validate_in_range();
        rhs.validate_in_range();
        denominator.validate_in_range();
        // Safety: the constrained path verifies the complete integer relation,
        // result limb ranges and Euclidean bounds; it does not trust helper checks.
        let (q, r) = unsafe { u256_division::div_rem(self, rhs, denominator) };
        if !std::runtime::is_unconstrained() {
            u256_constraints::verify_division(self, rhs, denominator, q, r);
        }
        (q, r)
    }

    fn mul_div_ceil(self, rhs: Self, denominator: Self) -> Self {
        let (q, r) = self.mul_div_rem(rhs, denominator);
        if r == U256::zero() {
            q
        } else {
            assert(q < U256::from_le_bytes([255; 32]), "mul_div: ceiling overflow");
            q + U256::one()
        }
    }
}

#[test]
fn wide_ratio_with_remainder() {
    // (2^64 + 1)^2 / 2^64 = 2^64 + 2, remainder 1.
    let a: u128 = 0x10000000000000001;
    assert_eq(a.mul_div_rem(a, 0x10000000000000000), (0x10000000000000002, 1));
    assert_eq(a.mul_div_floor(a, 0x10000000000000000), 0x10000000000000002);
}

#[test]
fn ceiling_rounding() {
    assert_eq(7_u128.mul_div_ceil(9, 4), 16);
    assert_eq(7_u128.mul_div_ceil(8, 4), 14);
    assert_eq(0_u128.mul_div_ceil(9, 4), 0);
    let m: u128 = 0xffffffffffffffffffffffffffffffff;
    assert_eq(m.mul_div_ceil(1, 1), m);
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn ceiling_only_overflow() {
    // (MAX - 1)^2 = MAX * (MAX - 2) + 1.
    let m: u128 = 0xffffffffffffffffffffffffffffffff;
    let _ = (m - 1).mul_div_ceil(m - 1, m - 2);
}
