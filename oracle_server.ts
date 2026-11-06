#!/usr/bin/env node

// Oracle server for the differential tests in `src/oracle_tests.nr`.
// Computes `a * b / d` exactly with JS BigInt, as an implementation independent
// of the library under test.

import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

type ForeignCallParam = string | string[];

interface ForeignCallInfo {
  function: string;
  inputs: ForeignCallParam[];
}

interface ForeignCallResult {
  values: ForeignCallParam[];
}

const U128_MAX = (1n << 128n) - 1n;
const U256_MAX = (1n << 256n) - 1n;

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.post("/", (req, res) => {
  const { method, params, id } = req.body;
  if (method !== "resolve_foreign_call") {
    res.json({ jsonrpc: "2.0", id, error: { code: -32601, message: "Method not found" } });
    return;
  }
  try {
    res.json({ jsonrpc: "2.0", id, result: handleForeignCall(params || []) });
  } catch (error) {
    res.json({ jsonrpc: "2.0", id, error: { code: -32000, message: String(error) } });
  }
});

function handleForeignCall(params: ForeignCallInfo[]): ForeignCallResult {
  const [{ function: functionName, inputs }] = params;
  switch (functionName) {
    case "mulDivU128":
      return mulDivU128(inputs);
    case "mulDivU256":
      return mulDivU256(inputs);
    default:
      throw new Error(`Unknown function: ${functionName}`);
  }
}

// The fields of the Noir `Reference<T>` struct, in declaration order.
interface Reference {
  remOk: boolean;
  q: bigint;
  r: bigint;
  ceilOk: boolean;
  ceil: bigint;
}

function reference(a: bigint, b: bigint, d: bigint, max: bigint): Reference {
  if (d === 0n) {
    return { remOk: false, q: 0n, r: 0n, ceilOk: false, ceil: 0n };
  }
  const product = a * b;
  const q = product / d;
  const r = product % d;
  const ceil = r === 0n ? q : q + 1n;
  const remOk = q <= max;
  return {
    remOk,
    q: remOk ? q : 0n,
    r: remOk ? r : 0n,
    ceilOk: ceil <= max,
    ceil: ceil <= max ? ceil : 0n,
  };
}

function toField(value: bigint): string {
  return value.toString(16).padStart(64, "0");
}

function fromField(hex: ForeignCallParam): bigint {
  if (typeof hex !== "string") throw new Error("expected a single field");
  return BigInt("0x" + (hex || "0"));
}

// `[u8; 32]` little-endian bytes.
function fromBytes(bytes: ForeignCallParam): bigint {
  if (!Array.isArray(bytes) || bytes.length !== 32) throw new Error("expected [u8; 32]");
  return bytes.reduceRight((acc, byte) => (acc << 8n) | fromField(byte), 0n);
}

function toBytes(value: bigint): string[] {
  const bytes: string[] = [];
  for (let i = 0; i < 32; i++) {
    bytes.push(toField((value >> BigInt(8 * i)) & 0xffn));
  }
  return bytes;
}

function mulDivU128(inputs: ForeignCallParam[]): ForeignCallResult {
  const [a, b, d] = inputs.map(fromField);
  const result = reference(a, b, d, U128_MAX);
  return {
    values: [
      toField(result.remOk ? 1n : 0n),
      toField(result.q),
      toField(result.r),
      toField(result.ceilOk ? 1n : 0n),
      toField(result.ceil),
    ],
  };
}

function mulDivU256(inputs: ForeignCallParam[]): ForeignCallResult {
  const [a, b, d] = inputs.map(fromBytes);
  const result = reference(a, b, d, U256_MAX);
  return {
    values: [
      toField(result.remOk ? 1n : 0n),
      toBytes(result.q),
      toBytes(result.r),
      toField(result.ceilOk ? 1n : 0n),
      toBytes(result.ceil),
    ],
  };
}

const PORT = process.env.PORT || 8095;
app.listen(PORT, () => {
  console.log(`Oracle server running on port ${PORT}`);
});
