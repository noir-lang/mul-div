# Performance measurements

A one-off comparison of this library against the general `bigint` multiply-divide
it specialises, measured with Noir 1.0.0 and Barretenberg 6.0.0 (`evm` verifier
target) against bigint commit `bacd1c0`. These figures
are a dated record and are not regenerated; current circuit and Brillig sizes come
from the benchmark workflow (`src/benchmarks.nr`).

## Circuit gates

Standalone consumers use private runtime inputs and public outputs. Counts include
range constraints and backend overhead. Compare within each type and adapter,
because the input/output representations differ between types.

| Type | Operation | Bigint baseline | Specialized |
| --- | --- | ---: | ---: |
| u128 | Floor | 4,112 | 3,063 |
| u128 | Quotient and remainder | 4,189 | 3,065 |
| u128 | Ceiling | 4,213 | 3,091 |

Circuit size is input-independent for a given adapter. It is not a proof time or padded proving-domain measurement.

## Constrained execution time

Each sample executed eight precompiled calls with independently computed
expected-result assertions. Runs use two warmups and 15 alternating samples per implementation.
These retained results came from u128 runs on an AMD EPYC 7R13.

| Type | Baseline median | Specialized median | Reduction |
| --- | ---: | ---: | ---: |
| u128 | 23.398 ms | 12.877 ms | 44.96% |

Timings include CLI startup, artifact/input loading and ACVM witness execution.
They exclude compilation, gate counting, witness serialization and proving.
They depend on machine/load and do not isolate the division helper. Batch gates
include output assertions and differ from standalone counts.
