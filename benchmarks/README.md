# Benchmarks

Use official Noir **1.0.0**, including `noir-execute`, and Barretenberg **6.0.0**
(`bbup -v 6.0.0`). Python **3.11+** is required.

```sh
python3 scripts/benchmark.py
python3 scripts/benchmark-witness.py
python3 scripts/benchmark-witness.py --width 256
```

`NARGO`, `NOIR_EXECUTE` and `BB` override executable paths.
Circuit measurement uses the `evm` verifier
target.

## Retained evidence

| Directory | Contents |
| --- | --- |
| `baseline/` | Original bigint circuit gate reports for u128 and U512-based U256 |
| `current/` | Specialized circuit reports and separate u128/U256 witness timings |
| `witness/` | Preserved baseline arithmetic and exact inputs used by timing comparisons |

Reports retain measured values and hashes, with discontinued multiplication
entries removed. Stored adapter names follow the current package naming; hashes
identify the original measured artifacts. The current directory identifies the specialized algorithms; its reports are historical runs and are not rewritten
when documentation or package metadata changes. See
[results and measurement scope](../docs/performance.md).

## Generated output

Fresh runs write into ignored `target/`:

- `circuit-report.json` contains consumer adapters, gate counts and ACIR hashes.
- `witness-report.json` and `u256-witness-report.json` contain raw timing samples,
  machine details, baseline source hashes, input fixtures and batch gate counts.
- `benchmark-acir_opcodes.json` and `benchmark-circuit_size.json` contain compact
  per-operation measurements.

CI uploads these files. Arithmetic source hashes cover the local library and its
manifest. The dependency tracks upstream bigint `main`; match dependency versions
as well as toolchains, adapters and operands when comparing runs. ACIR hashes
exclude debug metadata containing temporary paths.
