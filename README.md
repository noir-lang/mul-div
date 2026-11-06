# mul-div

Exact unsigned multiply-divide for Noir, with constrained and unconstrained
execution. Licensed under Apache-2.0.

## Noir Version Compatibility

This library requires Noir **v1.0.0** or later.

## Installation

`mul-div` and its `bigint` dependency are private repositories, so you need read
access to both. From a sibling checkout, add these dependencies to your `Nargo.toml`:

```toml
[dependencies]
mul_div = { path = "../mul-div" }
bigint = { git = "https://github.com/noir-lang/bigint", tag = "main" }
```

## API

The `MulDiv` trait is implemented for `u8`, `u16`, `u32`, `u64`, `u128` and bigint's `U256`:

| Method | Result |
| --- | --- |
| `a.mul_div_floor(b, d)` | `floor(a * b / d)` |
| `a.mul_div_ceil(b, d)` | `ceil(a * b / d)` |
| `a.mul_div_rem(b, d)` | Floor quotient and remainder `(q, r)` |

```noir
use bigint::{BigInt, U256};
use mul_div::MulDiv;

let (q, r) = (7 as u128).mul_div_rem(9, 4);
assert_eq(q, 15);
assert_eq(r, 3);
assert_eq((7 as u128).mul_div_ceil(9, 4), 16);

let maximum = U256::from_le_bytes([255; 32]);
assert_eq(maximum.mul_div_floor(maximum, maximum), maximum);
```

Multiply-divide preserves a product twice the operand width. It rejects a zero
denominator or a final quotient that exceeds the receiver's width. Ceiling also
rejects overflow of its rounding increment. Zero products return zero for a
nonzero denominator. Quotient and remainder satisfy `a*b = q*d+r` and `r < d`.

The same API works in circuits and unconstrained execution. See
[arithmetic and constraints](docs/arithmetic.md) for implementation details.

## Testing

Tests need Noir **1.0.0**, Node.js and Yarn. `scripts/run.sh` builds and starts the
oracle server, then runs `nargo test` twice: once on the constrained path and once
with `--force-brillig` on the unconstrained path.

```sh
noirup --version 1.0.0
yarn install
./scripts/run.sh
```

- `src/tests.nr` holds fixed boundary and regression cases, with the
  rejection cases as `should_fail_with` tests.
- `src/oracle_tests.nr` holds parametric tests whose random inputs are
  compared against an exact JS `BigInt` reference served by `oracle_server.ts`.
- `src/*_constraints.nr` tests supply incorrect witnesses directly to
  the division verifiers.

Plain `nargo test` without `--oracle-resolver` fails on the oracle tests.

## Performance

See [performance measurements](docs/performance.md) for a comparison with bigint's
general multiply-divide.

Based on [noir-library-starter](https://github.com/noir-lang/noir-library-starter).
