"""Shared toolchain checks and dependency setup for repository scripts."""
import hashlib
import json
from pathlib import Path
import subprocess
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd=ROOT, *, strip=True, combine_output=False):
    result = subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT if combine_output else subprocess.PIPE)
    if result.returncode:
        raise SystemExit(f'{args}\n{result.stdout}\n{result.stderr or ""}')
    return result.stdout.strip() if strip else result.stdout


def require_noir(version):
    if ('nargo version = 1.0.0\n' not in version or
            '275d3ab1a5c916c6ea73e8d6b943f685f574500c' not in version):
        raise SystemExit('Expected official Noir 1.0.0 compiler')


def require_backend(version):
    if version != '6.0.0':
        raise SystemExit('Expected Barretenberg 6.0.0')


def bigint_dependency():
    manifest = tomllib.loads((ROOT / 'Nargo.toml').read_text())
    dependency = manifest['dependencies']['bigint']
    fields = ', '.join(f'{key} = {json.dumps(value)}' for key, value in dependency.items())
    return f'bigint = {{ {fields} }}\n'


def source_hash():
    digest = hashlib.sha256()
    for path in [ROOT / 'Nargo.toml', *sorted((ROOT / 'src').rglob('*.nr'))]:
        if path.is_file():
            digest.update(str(path.relative_to(ROOT)).encode() + b'\0')
            digest.update(path.read_bytes() + b'\0')
    return digest.hexdigest()
