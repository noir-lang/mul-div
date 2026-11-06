// Specialized unconstrained arithmetic. See docs/arithmetic.md for bounds.
// Computes results directly in unconstrained execution and supplies circuit witnesses.
// Constrained callers must enforce the integer relation with u128_constraints.

global RADIX: u128 = 0x10000000000000000;
global DIGIT_MASK: u128 = RADIX - 1;
global MAXIMUM: u128 = 0xffffffffffffffffffffffffffffffff;

// Four 64-bit partial products fit exactly in BN254 field arithmetic.
// The combined low/cross terms are below 2^193, hence cannot wrap the field.
unconstrained fn product_halves(a: u128, b: u128) -> (u128, u128) {
    let a_low = (a & DIGIT_MASK) as Field;
    let a_high = (a >> 64) as Field;
    let b_low = (b & DIGIT_MASK) as Field;
    let b_high = (b >> 64) as Field;
    let radix = RADIX as Field;
    let cross = a_low * b_low + radix * (a_low * b_high + a_high * b_low);
    let low = cross as u128;
    // cross-low is an exact multiple of 2^128; the resulting high half fits u128.
    let high = a_high * b_high + (cross - low as Field) / (radix * radix);
    (low, high as u128)
}

// One radix-2^64 quotient digit. divisor >= 2^127 and high < divisor.
// The estimate is at most RADIX+1 and at most two above the true digit.
// All field intermediates are below 2^194. The corrected remainder is < divisor.
unconstrained fn quotient_digit(high: u128, low: u128, divisor: u128) -> (u128, u128) {
    let numerator = (high as Field) * (RADIX as Field) + low as Field;
    let mut quotient = high / (divisor >> 64);
    let mut product = (quotient as Field) * (divisor as Field);
    for _ in 0..2 {
        if numerator.lt(product) {
            quotient -= 1;
            product -= divisor as Field;
        } else {
            break;
        }
    }
    (quotient, (numerator - product) as u128)
}

pub(crate) unconstrained fn div_rem(a: u128, b: u128, denominator: u128) -> (u128, u128) {
    assert(denominator != 0, "mul_div: zero denominator");
    let (low, high) = product_halves(a, b);
    // a*b < denominator * 2^128 iff high < denominator.
    assert(high < denominator, "mul_div: quotient overflow");
    if denominator < RADIX {
        // Both partial numerators fit u128 because each incoming remainder is < d.
        let upper_numerator = (high << 64) | (low >> 64);
        let upper = upper_numerator / denominator;
        let remainder = upper_numerator % denominator;
        let lower_numerator = (remainder << 64) | (low & DIGIT_MASK);
        ((upper << 64) | (lower_numerator / denominator), lower_numerator % denominator)
    } else {
        let scale = MAXIMUM / denominator;
        // 2^127 <= denominator*scale < 2^128. Scaling preserves the quotient.
        let normalized = ((denominator as Field) * (scale as Field)) as u128;
        let (scaled_low, scaled_high) = if scale == 1 {
            (low, high)
        } else {
            let (bottom, carry) = product_halves(low, scale);
            (bottom, ((high as Field) * (scale as Field) + carry as Field) as u128)
        };
        let (upper, remainder) = quotient_digit(scaled_high, scaled_low >> 64, normalized);
        let (lower, scaled_remainder) =
            quotient_digit(remainder, scaled_low & DIGIT_MASK, normalized);
        // a*b*scale = q*d*scale + scaled_remainder: division by scale is exact.
        ((upper << 64) | lower, scaled_remainder / scale)
    }
}
