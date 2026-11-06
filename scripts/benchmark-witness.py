#!/usr/bin/env python3
"""Compare constrained mul_div_rem witness execution against the preserved bigint path."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import platform
import statistics
import tempfile
import time

from common import ROOT, bigint_dependency, require_backend, require_noir, run, source_hash


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--width', type=int, choices=[128, 256], default=128)
    parser.add_argument('--repetitions', type=int, default=15)
    args = parser.parse_args()
    if args.repetitions < 3:
        parser.error('use at least three repetitions')
    nargo = os.environ.get('NARGO', 'nargo')
    executor = os.environ.get('NOIR_EXECUTE', 'noir-execute')
    backend = os.environ.get('BB', 'bb')
    versions = {name: run([tool, '--version']) for name, tool in
                [('compiler', nargo), ('executor', executor), ('backend', backend)]}
    require_noir(versions['compiler'])
    require_backend(versions['backend'])
    expected_tools = {'executor': 'noir-execute version = 1.0.0'}
    for tool, expected_version in expected_tools.items():
        if versions[tool] != expected_version:
            raise SystemExit(f'Expected official Noir 1.0.0 {tool}')
    baseline = ROOT / 'benchmarks/witness' / ('bigint.nr' if args.width == 128 else 'u256-bigint.nr')
    inputs = ROOT / 'benchmarks/witness' / ('inputs.json' if args.width == 128 else 'u256-inputs.json')
    cases = json.loads(inputs.read_text())
    operands = [[int(case[key]) for case in cases] for key in ['a', 'b', 'd']]
    expected = [divmod(a * b, d) for a, b, d in zip(*operands)]
    assert all(0 <= q < 2**args.width and 0 <= r < d for (q, r), d in zip(expected, operands[2]))
    size = len(cases)
    value_type = 'u128' if args.width == 128 else '[u8; 32]'
    call_inputs = ', '.join(f'{name}[i]' if args.width == 128 else f'U256::from_le_bytes({name}[i])'
                           for name in ['a', 'b', 'd'])
    q_value = 'q' if args.width == 128 else 'q.to_le_bytes()'
    r_value = 'r' if args.width == 128 else 'r.to_le_bytes()'
    imports = '' if args.width == 128 else 'use bigint::{BigInt, U256};\n'
    adapter = imports + f'''fn main(a: [{value_type}; {size}], b: [{value_type}; {size}], d: [{value_type}; {size}], expected_q: [{value_type}; {size}], expected_r: [{value_type}; {size}]) {{
    for i in 0..{size} {{
        let (q, r) = IMPLEMENTATION::mul_div_rem({call_inputs});
        assert_eq({q_value}, expected_q[i]);
        assert_eq({r_value}, expected_r[i]);
    }}
}}
'''
    measurements = {}
    with tempfile.TemporaryDirectory(prefix='mul-div-witness-') as directory:
        workspace = Path(directory)
        (workspace / 'Nargo.toml').write_text('[workspace]\nmembers = ["baseline", "specialized"]\n')
        prover = workspace / 'inputs.toml'
        values = dict(zip(['a', 'b', 'd'], operands))
        values['expected_q'] = [q for q, _ in expected]
        values['expected_r'] = [r for _, r in expected]
        encoded = {key: [str(value) if args.width == 128 else list(value.to_bytes(32, 'little'))
                         for value in array] for key, array in values.items()}
        prover.write_text('\n'.join(f'{key} = {json.dumps(array)}'
                                    for key, array in encoded.items()) + '\n')
        for name in ['baseline', 'specialized']:
            package = workspace / name
            (package / 'src').mkdir(parents=True)
            (package / 'Nargo.toml').write_text(
                f'[package]\nname = "{name}"\ntype = "bin"\ncompiler_version = "=1.0.0"\n'
                '[dependencies]\n'
                f'mul_div = {{ path = {json.dumps(str(ROOT))} }}\n'
                + bigint_dependency())
            implementation = 'mul_div' if args.width == 128 else '<U256 as mul_div::MulDiv>'
            source = adapter.replace('IMPLEMENTATION', 'baseline' if name == 'baseline' else implementation)
            if name == 'baseline':
                (package / 'src/baseline.nr').write_text(baseline.read_text())
                source = 'mod baseline;\n' + source
            (package / 'src/main.nr').write_text(source)
        run([nargo, 'check', '--workspace', '--deny-warnings'], workspace)
        run([nargo, 'compile', '--workspace', '--deny-warnings'], workspace)
        commands = {}
        for name in ['baseline', 'specialized']:
            artifact = workspace / 'target' / f'{name}.json'
            commands[name] = [executor, '--artifact-path', str(artifact), '--prover-file', str(prover)]
            gates = json.loads(run([backend, 'gates', '-b', str(artifact), '--verifier_target', 'evm']))
            measurements[name] = {
                'batch_gates': gates['functions'][0]['circuit_size'],
                'acir_sha256': hashlib.sha256(base64.b64decode(json.loads(artifact.read_text())['bytecode'])).hexdigest(),
                'samples_ms': [],
            }
            # Warmup includes checking all results against the independent Python integer oracle.
            for _ in range(2):
                run(commands[name])
        # Alternate order to reduce systematic first/second-process bias.
        for trial in range(args.repetitions):
            order = ['baseline', 'specialized'] if trial % 2 == 0 else ['specialized', 'baseline']
            for name in order:
                start = time.perf_counter_ns()
                run(commands[name])
                measurements[name]['samples_ms'].append((time.perf_counter_ns() - start) / 1_000_000)
    for result in measurements.values():
        result['median_ms'] = statistics.median(result['samples_ms'])
        result['min_ms'] = min(result['samples_ms'])
        result['max_ms'] = max(result['samples_ms'])
    cpu_info = Path('/proc/cpuinfo')
    cpu_model = platform.processor()
    if cpu_info.exists():
        cpu_model = next((line.split(':', 1)[1].strip() for line in cpu_info.read_text().splitlines()
                          if line.startswith('model name')), cpu_model)
    report = {
        **versions, 'platform': platform.platform(), 'machine': platform.machine(),
        'cpu_model': cpu_model, 'logical_cpus': os.cpu_count(), 'calls_per_sample': size,
        'operand_bits': args.width, 'baseline_source_commit': 'bacd1c0' if args.width == 128 else '9248d54',
        'baseline_source_sha256': hashlib.sha256(baseline.read_bytes()).hexdigest(),
        'arithmetic_source_sha256': source_hash(), 'inputs': cases,
        'adapter_template': adapter, 'verifier_target': 'evm',
        'repetitions': args.repetitions, 'warmups_per_implementation': 2,
        'scope': 'Precompiled constrained mul_div_rem batch with independent expected-result assertions. Wall time includes CLI startup, artifact/input loading and ACVM witness solving; excludes compilation, gate counting, witness serialization and proving. Batch gate counts include the shared adapter/assertion overhead. Timing is machine/load dependent.',
        'measurements': measurements,
    }
    output = ROOT / 'target' / ('witness-report.json' if args.width == 128 else 'u256-witness-report.json')
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
