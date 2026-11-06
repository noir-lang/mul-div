# Arithmetic and circuit constraints

Multiply-divide computes quotient and remainder with specialized unconstrained
helpers, then verifies their integer relation when called from constrained code.
The public API exposes u128 and bigint U256. Temporary representations stay private.

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

## Circuit verification

An `unsafe` call from constrained code obtains untrusted quotient and remainder
witnesses. The constrained path enforces a nonzero denominator, `r < d`, canonical
values within the result width, and the full integer relation `a*b - q*d - r = 0`.

Both verifiers use bigint's `evaluate_quadratic_expression`. Its limb and bounded
carry constraints enforce the integer relation even when products exceed the
field modulus. A field equality alone would allow incorrect witnesses differing
by a multiple of that modulus. Assertions inside the unconstrained helper do not
establish circuit soundness.

For nonzero d, these conditions uniquely determine q and r. An overflowing
quotient has no valid in-range witness. Ceiling consumes the checked pair and
checks its increment before addition.

Private verifier tests supply incorrect quotients, remainders, noncanonical
encodings and field-congruent integer mismatches without using the honest
witness generator. Oracle-backed `nargo test` tests compare public API results
against an independent JS `BigInt` reference, and fixed tests cover normalization
and correction regressions.
