#!/usr/bin/env bash
set -eu

export PORT=${PORT:-8095}

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

echo "Building oracle server..."
yarn build

echo "Starting oracle server..."
# Start node directly rather than through `yarn start`: the trap below must
# kill the server process itself, or an orphaned server outlives this script.
node dist/oracle_server.js &
SERVER_PID=$!
trap 'kill $SERVER_PID' EXIT

# Wait for the server to accept connections.
for _ in $(seq 1 30); do
  if curl -s -o /dev/null "http://localhost:${PORT}"; then
    break
  fi
  sleep 0.5
done

nargo test --workspace --oracle-resolver "http://localhost:${PORT}" "$@"
nargo test --workspace --oracle-resolver "http://localhost:${PORT}" --force-brillig "$@"
