#!/usr/bin/env python3
"""Measure MulDiv circuit gates with Noir 1.0 and Barretenberg 6.0.0."""
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

from common import ROOT, bigint_dependency, require_backend, require_noir, run, source_hash

OPERATIONS = {
    'mul_div_floor': ('a: u128, b: u128, d: u128', 'u128', 'a, b, d'),
    'mul_div_rem': ('a: u128, b: u128, d: u128', '(u128, u128)', 'a, b, d'),
    'mul_div_ceil': ('a: u128, b: u128, d: u128', 'u128', 'a, b, d'),
}
for method in ['mul_div_floor', 'mul_div_rem', 'mul_div_ceil']:
    OPERATIONS[f'u256_{method}'] = (
        'a: bigint::U256, b: bigint::U256, d: bigint::U256',
        '(bigint::U256, bigint::U256)' if method == 'mul_div_rem' else 'bigint::U256',
        'a, b, d',
    )


def main():
    nargo = os.environ.get('NARGO', 'nargo')
    backend = os.environ.get('BB', 'aztec-bb')
    compiler = run([nargo, '--version'])
    backend_version = run([backend, '--version'])
    require_noir(compiler)
    require_backend(backend_version)
    programs = []
    with tempfile.TemporaryDirectory(prefix='mul-div-gates-') as directory:
        workspace = Path(directory)
        library = workspace / 'library'
        shutil.copytree(ROOT / 'src', library / 'src')
        shutil.copy(ROOT / 'Nargo.toml', library / 'Nargo.toml')
        for operation, (inputs, output, call) in OPERATIONS.items():
            package = workspace / operation
            (package / 'src').mkdir(parents=True)
            (package / 'Nargo.toml').write_text(
                f'[package]\nname = "{operation}"\ntype = "bin"\ncompiler_version = "=1.0.0"\n'
                '[dependencies]\nmul_div = { path = "../library" }\n'
                + bigint_dependency())
            function = (f'<bigint::U256 as mul_div::MulDiv>::{operation.removeprefix("u256_")}'
                        if operation.startswith('u256_') else f'mul_div::{operation}')
            adapter = f'fn main({inputs}) -> pub {output} {{\n    {function}({call})\n}}\n'
            (package / 'src/main.nr').write_text(adapter)
        (workspace / 'Nargo.toml').write_text(
            '[workspace]\nmembers = ' + json.dumps(list(OPERATIONS)) + '\n')
        run([nargo, 'check', '--workspace', '--deny-warnings'], workspace)
        run([nargo, 'compile', '--workspace', '--deny-warnings'], workspace)
        for operation in OPERATIONS:
            artifact = workspace / 'target' / f'{operation}.json'
            result = json.loads(run([backend, 'gates', '-b', str(artifact),
                                     '--verifier_target', 'evm']))
            function, = result['functions']
            for metric in ['acir_opcodes', 'circuit_size']:
                if type(function.get(metric)) is not int or function[metric] <= 0:
                    raise SystemExit(f'Missing or invalid {metric}: {result}')
            programs.append({
                'operation': operation, **function,
                'adapter': (workspace / operation / 'src/main.nr').read_text(),
                # Debug metadata contains temporary absolute paths; hash ACIR only.
                'acir_sha256': hashlib.sha256(base64.b64decode(
                    json.loads(artifact.read_text())['bytecode'])).hexdigest(),
            })
    report = {
        'implementation': 'MulDiv: specialized u128 and U256 witnesses with bigint integer constraints',
        'arithmetic_source_sha256': source_hash(),
        'compiler': compiler, 'backend': backend_version,
        'verifier_target': 'evm',
        'scope': 'One ordinary API call; private runtime inputs matching the adapter types and public result. Includes input/output constraints and backend overhead. No input constant folding or overhead subtraction. Circuit size is input-independent; not a proof time or padded-domain measurement.',
        'programs': programs,
    }
    target = ROOT / 'target'
    target.mkdir(exist_ok=True)
    (target / 'circuit-report.json').write_text(json.dumps(report, indent=2) + '\n')
    # Starter-compatible benchmark-action shape, without publishing to a host.
    for metric in ['acir_opcodes', 'circuit_size']:
        values = [{'name': p['operation'], 'unit': metric, 'value': p[metric]} for p in programs]
        (target / f'benchmark-{metric}.json').write_text(json.dumps(values, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
