# Basefee Surge Trap (Drosera Proof-of-Concept)

This repository contains a fully implemented, Drosera-compatible Proof of Concept trap designed to monitor **EIP-1559 basefee dynamics** on the Hoodi Testnet and emit a deterministic response when sudden basefee surges occur.

The project demonstrates a clear understanding of the Drosera trap lifecycle, strict adherence to the `ITrap` interface, safe payload construction, and clean separation between detection logic (trap) and execution logic (responder).

---

## Overview

Under EIP-1559, Ethereum’s basefee adjusts dynamically based on block-level demand. While normally gradual, basefee can spike sharply during sudden congestion events such as:

- short-lived demand bursts
- MEV-driven transaction competition
- coordinated block stuffing
- priority fee bidding wars

This trap focuses on **detecting abrupt basefee surges** between consecutive block samples collected by the Drosera relay. When the current basefee exceeds a defined multiple of the previous sample, the trap triggers a responder that emits structured event data for monitoring or downstream automation.

---

## Design Principles

This PoC is built around Drosera’s core architectural principles.

### 1. Stateless Execution

The trap maintains **no on-chain storage**.  
All decisions are derived exclusively from ordered samples supplied by the Drosera relay.

This guarantees:
- deterministic evaluation across operators
- replay safety
- zero storage writes
- planner-safe execution

---

### 2. Relay-Driven Sampling

The trap delegates all scheduling concerns to the Drosera relay, including:
- sample cadence
- block ordering
- cooldown enforcement
- operator coordination

The contract itself only answers one question:
**“Given these samples, should a response occur?”**

---

### 3. Predictable Threshold Logic

The surge condition is intentionally simple and transparent.

The trap triggers when:

```

currentBasefee >= previousBasefee * SURGE_MULTIPLIER

```

This avoids probabilistic heuristics and makes behavior easy to reason about, audit, and reproduce.

---

### 4. Planner-Safe Defensive Checks

The implementation includes explicit safety checks to prevent malformed inputs:

- verifies sufficient sample count
- validates byte length before decoding
- guards against zero basefee edge cases

These checks are critical for safe multi-operator evaluation.

---

## How the Trap Works

### 1. Data Collection

The `collect()` function is invoked by the Drosera relay and returns:

- the current block basefee
- the current block number

Encoded as:

```

abi.encode(block.basefee, block.number)

```

Each call produces one immutable sample for later evaluation.

---

### 2. Evaluation Phase

`shouldRespond(bytes[] calldata data)` receives the two most recent samples:

- `data[0]` → newest sample
- `data[1]` → previous sample

The trap:
1. Validates input integrity
2. Decodes both samples
3. Compares basefees using a fixed multiplier

If the surge condition is met, the trap returns:

```

(true, abi.encode(
address(0),
currentBasefee,
previousBasefee,
currentBlock,
"Basefee surge detected"
))

````

This encoded payload is forwarded directly to the responder.

---

### 3. Response Execution

The responder contract (`ResponseBasefee.sol`) receives the payload and emits a structured event containing:

- reporter address (currently zeroed)
- current basefee
- previous basefee
- block number
- human-readable reason string

No state is mutated, and no external calls are performed, preserving deterministic behavior.

---

## Use Cases

This trap can be used for:

- real-time congestion monitoring
- fee volatility analysis
- alerting systems
- MEV research
- automated responses to fee pressure

It also serves as a clean foundation for future extensions such as:
- adaptive thresholds
- rolling-window analysis
- statistical anomaly detection

---

## Deployment Summary

The contracts are deployed on the Hoodi Testnet.

| Contract             | Address                                      |
|----------------------|----------------------------------------------|
| ResponseBasefee      | 0x7eDBCA1450f90F1927cb5721302a209D1e109fc9 |
| BasefeeSurgeTrap     | 0xe5443D5CD2AeBB6930FaC46aA440D847d92A7584 |

---

## Network Configuration

- Chain: Hoodi Testnet  
- Chain ID: 560048  
- Ethereum RPC: https://ethereum-hoodi-rpc.publicnode.com  
- Drosera Relay: https://relay.hoodi.drosera.io  

---

## Operator Configuration

The provided `drosera.toml` is fully aligned with the deployed contracts and payload structure.

Operators can run the trap using:

```bash
drosera node
drosera operator --trap basefee_surge
````

---

## Repository Structure

```
src/
 ├─ BasefeeSurgeTrap.sol
 ├─ ResponseBasefee.sol
 └─ interfaces/
     └─ ITrap.sol

lib/
out/
foundry.toml
drosera.toml
README.md
```

Each component has a single responsibility and follows Drosera best practices.

---

## Safety Notes

This trap adheres strictly to Drosera safety expectations:

* no storage writes
* no dynamic state
* no external calls
* deterministic execution
* planner-safe decoding
* relay-compatible payloads
* private trap whitelisting support

---

## Acknowledgements

Thanks to the Drosera maintainers and reviewers for providing clear standards and constructive feedback.
This PoC incorporates lessons from official examples and community guidance across the Trappers’ Path.

```