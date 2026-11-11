# mul-div

> [!WARNING]
> **This library is experimental software. It has not been audited and is not guaranteed to be secure. Expect bugs!**
>
> mul-div is provided "as is", without warranty of any kind (see [LICENSE](LICENSE)). Bugs in this library can lead to under-constrained circuits, allowing invalid proofs to be accepted. Do not rely on it to protect real assets or sensitive data without your own independent review.
>
> If you find a vulnerability, please **do not** open a public issue. Report it privately via [GitHub's "Report a vulnerability"](https://github.com/noir-lang/mul-div/security/advisories/new) form instead.

Exact unsigned multiply-divide for Noir, with constrained and unconstrained
execution. Licensed under Apache-2.0.

## Noir Version Compatibility

This library requires Noir **v1.0.0** or later.

## Installation

Add `mul_div` to your `Nargo.toml`:

<!-- x-release-please-start-version -->

```toml
[dependencies]
mul_div = { git = "https://github.com/noir-lang/mul-div", tag = "v0.0.0" }
```

<!-- x-release-please-end -->

## API

The `MulDiv` trait is implemented for `u8`, `u16`, `u32`, `u64` and `u128`. It is a public trait, so
other libraries can implement it for their own integer types.

| Method | Result |
| --- | --- |
| `a.mul_div_floor(b, d)` | `floor(a * b / d)` |
| `a.mul_div_ceil(b, d)` | `ceil(a * b / d)` |
| `a.mul_div_rem(b, d)` | Floor quotient and remainder `(q, r)` |

```noir
use mul_div::MulDiv;

let (q, r) = 7_u128.mul_div_rem(9, 4);
assert_eq(q, 15);
assert_eq(r, 3);
assert_eq(7_u128.mul_div_ceil(9, 4), 16);
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

The Benchmarks workflow measures circuit size, ACIR opcodes and Brillig bytecode
size for every operation in `src/benchmarks.nr`, and posts the per-function diff
against `master` on each pull request.

Based on [noir-library-starter](https://github.com/noir-lang/noir-library-starter).
