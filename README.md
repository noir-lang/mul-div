# mul-div

Exact unsigned multiply-divide for Noir, with constrained and unconstrained
execution. Licensed under Apache-2.0.

## Installation

From a sibling checkout, add these dependencies to your `Nargo.toml`:

```toml
[dependencies]
mul_div = { path = "../mul-div/library" }
bigint = { git = "https://github.com/noir-lang/bigint", tag = "main" }
```

## API

| Free function | Result |
| --- | --- |
| `mul_div_floor(a: u128, b: u128, d: u128)` | Floor quotient as u128 |
| `mul_div_ceil(a: u128, b: u128, d: u128)` | Ceiling quotient as u128 |
| `mul_div_rem(a: u128, b: u128, d: u128)` | Floor quotient and remainder as `(u128, u128)` |

`MulDiv` provides the three division methods for both u128 and bigint U256:

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

Tests need Noir **1.0.0** and Node.js. Yarn is pinned by `packageManager` in
`package.json` and installed through Corepack. `scripts/run.sh` builds and starts the
oracle server, then runs `nargo test` twice: once on the constrained path and once
with `--force-brillig` on the unconstrained path.

```sh
noirup --version 1.0.0
corepack enable
yarn install
./scripts/run.sh
```

- `library/src/tests.nr` holds fixed boundary and regression cases, with the
  rejection cases as `should_fail_with` tests.
- `library/src/oracle_tests.nr` holds parametric tests whose random inputs are
  compared against an exact JS `BigInt` reference served by `oracle_server.ts`.
- `library/src/*_constraints.nr` tests supply incorrect witnesses directly to
  the division verifiers.

Plain `nargo test --workspace` without `--oracle-resolver` fails on the oracle tests.

See [benchmark commands and results](benchmarks/README.md) for benchmarks.

## Performance

Standalone circuit consumers use 3,063 gates for u128 floor multiply-divide and
2,958 for U256. See [measurement scope and comparisons](docs/performance.md).

CI runs stable tests, benchmarks and a nightly compatibility probe.
The manual release-preparation workflow runs checks only. Before publication,
choose a destination repository and version, test remote installation using the
`library` directory, and decide whether to keep bigint on `main` or select a fixed
upstream tag. Release automation is not configured.

Based on [noir-library-starter](https://github.com/noir-lang/noir-library-starter).
