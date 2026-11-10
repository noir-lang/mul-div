//! Fixed boundary and regression cases with expected values computed by an
//! independent big-integer reference. Every case runs the constrained path in a
//! normal `nargo test` run and the unconstrained path under `--force-brillig`.

use crate::MulDiv;

/// (a, b, d, floor quotient, remainder, ceiling quotient) for inputs every operation accepts.
global U128_CASES: [(u128, u128, u128, u128, u128, u128); 29] = [
    (0x0, 0xffffffffffffffffffffffffffffffff, 0x1, 0x0, 0x0, 0x0),
    (0xffffffffffffffffffffffffffffffff, 0x0, 0xffffffffffffffffffffffffffffffff, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0xffffffffffffffffffffffffffffffff, 0x0, 0x0, 0x0),
    (0x1, 0x1, 0x2, 0x0, 0x1, 0x1),
    (0x7, 0x9, 0x4, 0xf, 0x3, 0x10),
    (
        0xffffffffffffffffffffffffffffffff, 0x1, 0x1, 0xffffffffffffffffffffffffffffffff, 0x0,
        0xffffffffffffffffffffffffffffffff,
    ),
    (
        0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff, 0x0,
        0xffffffffffffffffffffffffffffffff,
    ),
    (
        0x10000000000000000, 0x10000000000000000, 0x2, 0x80000000000000000000000000000000, 0x0,
        0x80000000000000000000000000000000,
    ),
    (
        0x10000000000000000, 0x10000000000000000, 0x10000000000000000, 0x10000000000000000, 0x0,
        0x10000000000000000,
    ),
    (
        0x10000000000000001, 0x10000000000000001, 0x10000000000000000, 0x10000000000000002, 0x1,
        0x10000000000000003,
    ),
    (
        0xffffffffffffffffffffffffffffffff, 0x2, 0x2, 0xffffffffffffffffffffffffffffffff, 0x0,
        0xffffffffffffffffffffffffffffffff,
    ),
    (
        0xffffffffffffffffffffffffffffffff, 0x2, 0x3, 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0x0,
        0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,
    ),
    (
        0x10000000000000000, 0x10000000000000000, 0xffffffffffffffff, 0x10000000000000001, 0x1,
        0x10000000000000002,
    ),
    (
        0x10000000000000000, 0x10000000000000000, 0x10000000000000001, 0xffffffffffffffff, 0x1,
        0x10000000000000000,
    ),
    (0x0, 0x0, 0x10000000000000000, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0x80000000000000000000000000000000, 0x0, 0x0, 0x0),
    (0x1, 0x10000000000000000, 0x10000000000000001, 0x0, 0x10000000000000000, 0x1),
    (
        0x1, 0x80000000000000000000000000000000, 0x80000000000000000000000000000001, 0x0,
        0x80000000000000000000000000000000, 0x1,
    ),
    (
        0x2, 0x80000000000000000000000000000000, 0x10000000000000001, 0xffffffffffffffff, 0x1,
        0x10000000000000000,
    ),
    (
        0x10000000000000000, 0x80000000000000000000000000000000, 0x80000000000000000000000000000001,
        0xffffffffffffffff, 0x7fffffffffffffff0000000000000001, 0x10000000000000000,
    ),
    (
        0x10000000000000001, 0x7fffffffffffffffffffffffffffffff, 0x10000000000000001,
        0x7fffffffffffffffffffffffffffffff, 0x0, 0x7fffffffffffffffffffffffffffffff,
    ),
    (
        0x7fffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffffffffe,
        0xfffffffffffffffffffffffffffffffe, 0x7fffffffffffffffffffffffffffffff, 0x0,
        0x7fffffffffffffffffffffffffffffff,
    ),
    (
        0x85ada4e2860eea3066d0346e82d1de75, 0x50e80f8b427d44383903fd359bd01212,
        0x2aacac371128211961d70dbf5216b4e1, 0xfd70bb913d2a4eacf74a8f3bc52162d9,
        0x2a11dba52b48e7d24b4c2ed3cdf76981, 0xfd70bb913d2a4eacf74a8f3bc52162da,
    ),
    (
        0x72182d4fb83855ae5f0b2012f27ef5b4, 0xab187af5a319b26b25e65390427c989a,
        0x8dccb709b8385057d612e038a27924d9, 0x89aa9ddace670913d018830d2d5cc696,
        0x7fe3da4a72fe946bf47b859764fb4122, 0x89aa9ddace670913d018830d2d5cc697,
    ),
    (
        0xcb0c34190991ad734e7abffa98b8c2e5, 0x489f30add8cb0e02e7a30b2c10003ed0,
        0x433b878d4f89e7efff6cca149879d5c1, 0xdb52e3c03955a64ef41f86dd552bc73b,
        0x89affea5128287f9e085bd04fa98595, 0xdb52e3c03955a64ef41f86dd552bc73c,
    ),
    (
        0x14da46af749ca05e057d8859e83e57f9, 0x347e7a7f96430fbd6a9a404594d93ffe,
        0xa8e6dbd537d1d9cbed100c19972d250b, 0x67b1dda5dfc0addf5355849ea5f0922,
        0x9a3bf448d467dff0590c0fb6d4314198, 0x67b1dda5dfc0addf5355849ea5f0923,
    ),
    (
        0x8e26ac5f826e8d729860820838491a74, 0xf7f56f4ef367ebea68329d373e3afdde,
        0x9cb6c22482959c59f18c0ed8d8bcfdec, 0xe0eab74a9df233fafeeb30093a107b9b,
        0x15ddd4e86c25cae047ca7293c5a372b4, 0xe0eab74a9df233fafeeb30093a107b9c,
    ),
    (
        0x9d69af2fd6672cc8af25e8ba05bff13f, 0x4c80d0b47cfc97b50b376f0187ac5f8f,
        0x5896e3f632642519e411e7281e6c4cb4, 0x87efe1ae75b6c0e2e69e1bbd0908d86f,
        0x5785fae0156490d3942dec6f74c50125, 0x87efe1ae75b6c0e2e69e1bbd0908d870,
    ),
    (
        0xf6a7a1f962146a1864022ca1f7701521, 0x763274664e162b8196f4fcdc8dfbd610,
        0x82b14d7d0874c474f373f15671dc1b91, 0xdf127a975395c1c8ef7e3c71f6ee906d,
        0x3804f6b62e5e69ce633943e0cbfe9b53, 0xdf127a975395c1c8ef7e3c71f6ee906e,
    ),
];

fn check_u128_case(case: (u128, u128, u128, u128, u128, u128)) {
    let (a, b, d, q, r, ceil) = case;
    assert_eq(a.mul_div_rem(b, d), (q, r));
    assert_eq(a.mul_div_floor(b, d), q);
    assert_eq(a.mul_div_ceil(b, d), ceil);
}

#[test]
fn u128_boundaries() {
    for case in U128_CASES {
        check_u128_case(case);
    }
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_0_0_rem_rejects() {
    let _ = 0x0_u128.mul_div_rem(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_0_0_floor_rejects() {
    let _ = 0x0_u128.mul_div_floor(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_0_0_ceil_rejects() {
    let _ = 0x0_u128.mul_div_ceil(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_max_0_rem_rejects() {
    let _ = 0x0_u128.mul_div_rem(0xffffffffffffffffffffffffffffffff, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_max_0_floor_rejects() {
    let _ = 0x0_u128.mul_div_floor(0xffffffffffffffffffffffffffffffff, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_0_max_0_ceil_rejects() {
    let _ = 0x0_u128.mul_div_ceil(0xffffffffffffffffffffffffffffffff, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_max_0_0_rem_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_rem(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_max_0_0_floor_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_floor(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_max_0_0_ceil_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_ceil(0x0, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_1_1_0_rem_rejects() {
    let _ = 0x1_u128.mul_div_rem(0x1, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_1_1_0_floor_rejects() {
    let _ = 0x1_u128.mul_div_floor(0x1, 0x0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u128_1_1_0_ceil_rejects() {
    let _ = 0x1_u128.mul_div_ceil(0x1, 0x0);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_2pow64_2pow64_1_rem_rejects() {
    let _ = 0x10000000000000000_u128.mul_div_rem(0x10000000000000000, 0x1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_2pow64_2pow64_1_floor_rejects() {
    let _ = 0x10000000000000000_u128.mul_div_floor(0x10000000000000000, 0x1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_2pow64_2pow64_1_ceil_rejects() {
    let _ = 0x10000000000000000_u128.mul_div_ceil(0x10000000000000000, 0x1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_max_max_minus_1_rem_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_rem(
        0xffffffffffffffffffffffffffffffff,
        0xfffffffffffffffffffffffffffffffe,
    );
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_max_max_minus_1_floor_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_floor(
        0xffffffffffffffffffffffffffffffff,
        0xfffffffffffffffffffffffffffffffe,
    );
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_max_max_minus_1_ceil_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_ceil(
        0xffffffffffffffffffffffffffffffff,
        0xfffffffffffffffffffffffffffffffe,
    );
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_2_1_rem_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_rem(0x2, 0x1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_2_1_floor_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_floor(0x2, 0x1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u128_max_2_1_ceil_rejects() {
    let _ = 0xffffffffffffffffffffffffffffffff_u128.mul_div_ceil(0x2, 0x1);
}

#[test]
fn u128_max_minus_1_max_minus_1_max_minus_2_floor_fits() {
    assert_eq(
        0xfffffffffffffffffffffffffffffffe_u128.mul_div_rem(
            0xfffffffffffffffffffffffffffffffe,
            0xfffffffffffffffffffffffffffffffd,
        ),
        (0xffffffffffffffffffffffffffffffff, 0x1),
    );
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn u128_max_minus_1_max_minus_1_max_minus_2_ceil_rejects() {
    let _ = 0xfffffffffffffffffffffffffffffffe_u128.mul_div_ceil(
        0xfffffffffffffffffffffffffffffffe,
        0xfffffffffffffffffffffffffffffffd,
    );
}

/// (a, b, d, floor quotient, remainder, ceiling quotient) for inputs every operation accepts.
global U8_CASES: [(u8, u8, u8, u8, u8, u8); 15] = [
    (0x0, 0xff, 0x1, 0x0, 0x0, 0x0),
    (0xff, 0x0, 0xff, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0xff, 0x0, 0x0, 0x0),
    (0x1, 0x1, 0x2, 0x0, 0x1, 0x1),
    (0x7, 0x9, 0x4, 0xf, 0x3, 0x10),
    (0xff, 0x1, 0x1, 0xff, 0x0, 0xff),
    (0xff, 0xff, 0xff, 0xff, 0x0, 0xff),
    (0x10, 0x10, 0x2, 0x80, 0x0, 0x80),
    (0x10, 0x10, 0x10, 0x10, 0x0, 0x10),
    (0x11, 0x11, 0x10, 0x12, 0x1, 0x13),
    (0xff, 0x2, 0x2, 0xff, 0x0, 0xff),
    (0xff, 0x2, 0x3, 0xaa, 0x0, 0xaa),
    (0x10, 0x10, 0xf, 0x11, 0x1, 0x12),
    (0x10, 0x10, 0x11, 0xf, 0x1, 0x10),
    (0xff, 0xfe, 0xff, 0xfe, 0x0, 0xfe),
];

#[test]
fn u8_boundaries() {
    for case in U8_CASES {
        let (a, b, d, q, r, ceil) = case;
        assert_eq(a.mul_div_rem(b, d), (q, r));
        assert_eq(a.mul_div_floor(b, d), q);
        assert_eq(a.mul_div_ceil(b, d), ceil);
    }
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u8_zero_denominator_rem_rejects() {
    let _ = 1_u8.mul_div_rem(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u8_zero_denominator_floor_rejects() {
    let _ = 1_u8.mul_div_floor(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u8_zero_denominator_ceil_rejects() {
    let _ = 1_u8.mul_div_ceil(1, 0);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u8_quotient_overflow_rem_rejects() {
    let _ = 0xff_u8.mul_div_rem(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u8_quotient_overflow_floor_rejects() {
    let _ = 0xff_u8.mul_div_floor(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u8_quotient_overflow_ceil_rejects() {
    let _ = 0xff_u8.mul_div_ceil(2, 1);
}

#[test]
fn u8_max_minus_1_squared_floor_fits() {
    assert_eq(0xfe_u8.mul_div_rem(0xfe, 0xfd), (0xff, 1));
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn u8_ceiling_overflow_rejects() {
    let _ = 0xfe_u8.mul_div_ceil(0xfe, 0xfd);
}

/// (a, b, d, floor quotient, remainder, ceiling quotient) for inputs every operation accepts.
global U16_CASES: [(u16, u16, u16, u16, u16, u16); 15] = [
    (0x0, 0xffff, 0x1, 0x0, 0x0, 0x0),
    (0xffff, 0x0, 0xffff, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0xffff, 0x0, 0x0, 0x0),
    (0x1, 0x1, 0x2, 0x0, 0x1, 0x1),
    (0x7, 0x9, 0x4, 0xf, 0x3, 0x10),
    (0xffff, 0x1, 0x1, 0xffff, 0x0, 0xffff),
    (0xffff, 0xffff, 0xffff, 0xffff, 0x0, 0xffff),
    (0x100, 0x100, 0x2, 0x8000, 0x0, 0x8000),
    (0x100, 0x100, 0x100, 0x100, 0x0, 0x100),
    (0x101, 0x101, 0x100, 0x102, 0x1, 0x103),
    (0xffff, 0x2, 0x2, 0xffff, 0x0, 0xffff),
    (0xffff, 0x2, 0x3, 0xaaaa, 0x0, 0xaaaa),
    (0x100, 0x100, 0xff, 0x101, 0x1, 0x102),
    (0x100, 0x100, 0x101, 0xff, 0x1, 0x100),
    (0xffff, 0xfffe, 0xffff, 0xfffe, 0x0, 0xfffe),
];

#[test]
fn u16_boundaries() {
    for case in U16_CASES {
        let (a, b, d, q, r, ceil) = case;
        assert_eq(a.mul_div_rem(b, d), (q, r));
        assert_eq(a.mul_div_floor(b, d), q);
        assert_eq(a.mul_div_ceil(b, d), ceil);
    }
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u16_zero_denominator_rem_rejects() {
    let _ = 1_u16.mul_div_rem(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u16_zero_denominator_floor_rejects() {
    let _ = 1_u16.mul_div_floor(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u16_zero_denominator_ceil_rejects() {
    let _ = 1_u16.mul_div_ceil(1, 0);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u16_quotient_overflow_rem_rejects() {
    let _ = 0xffff_u16.mul_div_rem(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u16_quotient_overflow_floor_rejects() {
    let _ = 0xffff_u16.mul_div_floor(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u16_quotient_overflow_ceil_rejects() {
    let _ = 0xffff_u16.mul_div_ceil(2, 1);
}

#[test]
fn u16_max_minus_1_squared_floor_fits() {
    assert_eq(0xfffe_u16.mul_div_rem(0xfffe, 0xfffd), (0xffff, 1));
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn u16_ceiling_overflow_rejects() {
    let _ = 0xfffe_u16.mul_div_ceil(0xfffe, 0xfffd);
}

/// (a, b, d, floor quotient, remainder, ceiling quotient) for inputs every operation accepts.
global U32_CASES: [(u32, u32, u32, u32, u32, u32); 15] = [
    (0x0, 0xffffffff, 0x1, 0x0, 0x0, 0x0),
    (0xffffffff, 0x0, 0xffffffff, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0xffffffff, 0x0, 0x0, 0x0),
    (0x1, 0x1, 0x2, 0x0, 0x1, 0x1),
    (0x7, 0x9, 0x4, 0xf, 0x3, 0x10),
    (0xffffffff, 0x1, 0x1, 0xffffffff, 0x0, 0xffffffff),
    (0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0x0, 0xffffffff),
    (0x10000, 0x10000, 0x2, 0x80000000, 0x0, 0x80000000),
    (0x10000, 0x10000, 0x10000, 0x10000, 0x0, 0x10000),
    (0x10001, 0x10001, 0x10000, 0x10002, 0x1, 0x10003),
    (0xffffffff, 0x2, 0x2, 0xffffffff, 0x0, 0xffffffff),
    (0xffffffff, 0x2, 0x3, 0xaaaaaaaa, 0x0, 0xaaaaaaaa),
    (0x10000, 0x10000, 0xffff, 0x10001, 0x1, 0x10002),
    (0x10000, 0x10000, 0x10001, 0xffff, 0x1, 0x10000),
    (0xffffffff, 0xfffffffe, 0xffffffff, 0xfffffffe, 0x0, 0xfffffffe),
];

#[test]
fn u32_boundaries() {
    for case in U32_CASES {
        let (a, b, d, q, r, ceil) = case;
        assert_eq(a.mul_div_rem(b, d), (q, r));
        assert_eq(a.mul_div_floor(b, d), q);
        assert_eq(a.mul_div_ceil(b, d), ceil);
    }
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u32_zero_denominator_rem_rejects() {
    let _ = 1_u32.mul_div_rem(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u32_zero_denominator_floor_rejects() {
    let _ = 1_u32.mul_div_floor(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u32_zero_denominator_ceil_rejects() {
    let _ = 1_u32.mul_div_ceil(1, 0);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u32_quotient_overflow_rem_rejects() {
    let _ = 0xffffffff_u32.mul_div_rem(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u32_quotient_overflow_floor_rejects() {
    let _ = 0xffffffff_u32.mul_div_floor(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u32_quotient_overflow_ceil_rejects() {
    let _ = 0xffffffff_u32.mul_div_ceil(2, 1);
}

#[test]
fn u32_max_minus_1_squared_floor_fits() {
    assert_eq(0xfffffffe_u32.mul_div_rem(0xfffffffe, 0xfffffffd), (0xffffffff, 1));
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn u32_ceiling_overflow_rejects() {
    let _ = 0xfffffffe_u32.mul_div_ceil(0xfffffffe, 0xfffffffd);
}

/// (a, b, d, floor quotient, remainder, ceiling quotient) for inputs every operation accepts.
global U64_CASES: [(u64, u64, u64, u64, u64, u64); 15] = [
    (0x0, 0xffffffffffffffff, 0x1, 0x0, 0x0, 0x0),
    (0xffffffffffffffff, 0x0, 0xffffffffffffffff, 0x0, 0x0, 0x0),
    (0x0, 0x0, 0xffffffffffffffff, 0x0, 0x0, 0x0),
    (0x1, 0x1, 0x2, 0x0, 0x1, 0x1),
    (0x7, 0x9, 0x4, 0xf, 0x3, 0x10),
    (0xffffffffffffffff, 0x1, 0x1, 0xffffffffffffffff, 0x0, 0xffffffffffffffff),
    (
        0xffffffffffffffff, 0xffffffffffffffff, 0xffffffffffffffff, 0xffffffffffffffff, 0x0,
        0xffffffffffffffff,
    ),
    (0x100000000, 0x100000000, 0x2, 0x8000000000000000, 0x0, 0x8000000000000000),
    (0x100000000, 0x100000000, 0x100000000, 0x100000000, 0x0, 0x100000000),
    (0x100000001, 0x100000001, 0x100000000, 0x100000002, 0x1, 0x100000003),
    (0xffffffffffffffff, 0x2, 0x2, 0xffffffffffffffff, 0x0, 0xffffffffffffffff),
    (0xffffffffffffffff, 0x2, 0x3, 0xaaaaaaaaaaaaaaaa, 0x0, 0xaaaaaaaaaaaaaaaa),
    (0x100000000, 0x100000000, 0xffffffff, 0x100000001, 0x1, 0x100000002),
    (0x100000000, 0x100000000, 0x100000001, 0xffffffff, 0x1, 0x100000000),
    (
        0xffffffffffffffff, 0xfffffffffffffffe, 0xffffffffffffffff, 0xfffffffffffffffe, 0x0,
        0xfffffffffffffffe,
    ),
];

#[test]
fn u64_boundaries() {
    for case in U64_CASES {
        let (a, b, d, q, r, ceil) = case;
        assert_eq(a.mul_div_rem(b, d), (q, r));
        assert_eq(a.mul_div_floor(b, d), q);
        assert_eq(a.mul_div_ceil(b, d), ceil);
    }
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u64_zero_denominator_rem_rejects() {
    let _ = 1_u64.mul_div_rem(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u64_zero_denominator_floor_rejects() {
    let _ = 1_u64.mul_div_floor(1, 0);
}

#[test(should_fail_with = "mul_div: zero denominator")]
fn u64_zero_denominator_ceil_rejects() {
    let _ = 1_u64.mul_div_ceil(1, 0);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u64_quotient_overflow_rem_rejects() {
    let _ = 0xffffffffffffffff_u64.mul_div_rem(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u64_quotient_overflow_floor_rejects() {
    let _ = 0xffffffffffffffff_u64.mul_div_floor(2, 1);
}

#[test(should_fail_with = "mul_div: quotient overflow")]
fn u64_quotient_overflow_ceil_rejects() {
    let _ = 0xffffffffffffffff_u64.mul_div_ceil(2, 1);
}

#[test]
fn u64_max_minus_1_squared_floor_fits() {
    assert_eq(
        0xfffffffffffffffe_u64.mul_div_rem(0xfffffffffffffffe, 0xfffffffffffffffd),
        (0xffffffffffffffff, 1),
    );
}

#[test(should_fail_with = "mul_div: ceiling overflow")]
fn u64_ceiling_overflow_rejects() {
    let _ = 0xfffffffffffffffe_u64.mul_div_ceil(0xfffffffffffffffe, 0xfffffffffffffffd);
}
