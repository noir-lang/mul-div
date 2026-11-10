# Arithmetic and circuit constraints

Multiply-divide computes quotient and remainder with specialized unconstrained
helpers, then verifies their integer relation when called from constrained code.
The public API exposes u8 through u128 and bigint U256. Temporary representations stay private.

## u128 computation

Let B = 2^64 and W = 2^128. Split each factor into two base-B digits and compute
the exact product as two u128 halves, `N = low + W*high`. Product intermediates
are below 2^193 and the BN254 scalar modulus. Field division by W recovers an
integer carry because its numerator is an exact multiple of W and the quotient
is below the field modulus.

For nonzero d, the quotient fits u128 exactly when `high < d`. A divisor below B
uses two native u128 division steps. Each step combines a remainder below d with
one base-B digit, so its numerator fits u128.

For larger d, multiply numerator and denominator by `floor((W-1)/d)`. The scaled
denominator D lies in `[W/2, W)`. The quotient-fit check ensures the scaled product
fits two u128 halves. Two base-B steps estimate each quotient digit using the
leading divisor digit and correct by at most two decrements. The estimate can
exceed B before correction and must retain its u128 width. Correction
intermediates are below 2^194, so field comparisons agree with integer comparisons.
Divide the final remainder by the normalization factor to recover the original.

## U256 computation

Validate bigint's canonical 120/120/16-bit limbs, then convert each operand to
four base-B digits. Multiplication produces eight digits. A convolution column
contains at most four 64-by-64-bit products plus carry, below 2^130 and the BN254
modulus. The quotient fits U256 exactly when the upper four product digits
represent a value below the nonzero divisor.

A one-digit divisor uses four native u128 division steps. For longer divisors,
let t be the leading divisor digit. Multiplication by `floor(B/(t+1))` puts the
leading digit at least B/2 without increasing the divisor's digit count. The
quotient-fit check ensures the scaled product fits eight digits.

Each of four quotient steps estimates a digit from the leading two dividend
digits and the leading divisor digit, clamping the equal-leading-digit case to
B-1. The estimate is an upper bound at most two above the true digit. Compare the
full candidate product with the dividend window, correct it, and subtract.
Unscaling the remainder uses exact integer division.

Scaling multiply-adds fit u128 because digits and factor are below B and carry
is below the factor. Digit subtraction adds B before subtracting the other digit
and borrow. A final assertion rejects subtraction underflow.

## u8, u16, u32 and u64

For operands of at most 64 bits the full product fits in a `u128`, so an
unconstrained hint computes `(q, r)` with native `u128` division and returns them
as the operand type. That return range-checks both to the type's width. The circuit
checks `d != 0`, `r < d` and the single field equation `a*b = q*d + r`. Every term
is below 2^128, so the equation cannot wrap the field and holds over the integers.
Together with the range checks, it fixes the unique quotient and remainder.

## Circuit verification

An `unsafe` call from constrained code obtains untrusted quotient and remainder
witnesses. The constrained path enforces a nonzero denominator, `r < d`, canonical
values within the result width, and the full integer relation `a*b - q*d - r = 0`.

Products can exceed the field modulus p, so a field equality alone would allow
incorrect witnesses whose `a*b - q*d - r` is a nonzero multiple of p. Each verifier
closes that gap differently. Assertions inside the unconstrained helper do not
establish circuit soundness.

The u128 verifier checks the relation twice. With every operand below 2^128,
`D = a*b - q*d - r` satisfies `|D| < 2^257`. It checks `D = 0` once as a native field
equation (mod p) and once on the low 14-bit limbs of the five values (mod 2^14). Each
value is split as `x = 2^14*hi + lo` with `lo < 2^14` and `hi < 2^114`, which fixes
`lo = x mod 2^14`. Since p is odd, D is a multiple of `2^14 * p > 2^257`, so `D = 0`.
The 14-bit limb width reuses the range-check table that u128 values already need.

The U256 verifier uses bigint's `evaluate_quadratic_expression`, whose limb and
bounded carry constraints enforce the integer relation.

For nonzero d, these conditions uniquely determine q and r. An overflowing
quotient has no valid in-range witness. Ceiling consumes the checked pair and
checks its increment before addition.

Private verifier tests supply incorrect quotients, remainders, noncanonical
encodings, field-congruent integer mismatches, limb-congruent field mismatches and
dishonest u128 limb splits without using the honest witness generator.
Oracle-backed `nargo test` tests compare public API results against an independent
JS `BigInt` reference, and fixed tests cover normalization and correction
regressions.
