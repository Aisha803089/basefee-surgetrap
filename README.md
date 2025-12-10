
# **Basefee Surge Trap (Drosera Proof-of-Concept)**

This repository contains a fully-implemented, Drosera-compatible Proof of Concept trap designed to monitor **EIP-1559 basefee behavior** on the Hoodi Testnet and produce a deterministic response when sudden spikes occur. The trap follows Drosera’s strict interface requirements, maintains planner safety, operates in a stateless manner, and is compatible with multi-operator validation under the Drosera relay network.

The purpose of this PoC is to demonstrate clear understanding of the Drosera architecture, clean separation between the trap and its responder, and safe use of the ITrap interface while handling block state data across consecutive block samples.

---

## **Overview**

EIP-1559 introduced a dynamical mechanism in which the basefee adjusts per block based on network congestion. This trap focuses on detecting *sharp upward shifts* in the basefee between consecutive samples collected by the Drosera relay. These types of sudden basefee spikes often correlate with:

* short-duration congestion waves
* bursty transaction load
* potential MEV-driven manipulation
* abnormally high priority fee competition

The trap analyzes a pair of sequential observations, comparing the previous and current basefee, and triggers a response only when the increase surpasses a defined threshold. The responder then emits structured logs that make it easy to track network behavior or build analytics around basefee volatility.

---

## **Design Goals**

This PoC was built around Drosera’s core principles:

### **1. Statelessness**

The trap stores *no state* and infers everything purely from sequential `collect()` samples.
This ensures:

* deterministic operation across multiple operators
* zero storage writes
* replay safety
* planner-safe evaluation

### **2. Relay-First Architecture**

The trap assumes the Drosera relay is responsible for:

* scheduling execution
* feeding the ordered samples
* determining sampling intervals
* enforcing cooldown periods

The trap itself only supplies logic for *when* a response should occur.

### **3. Clean, Minimal, Predictable Logic**

The threshold comparison is intentionally simple:

```
if (currentBasefee > previousBasefee + THRESHOLD) => respond
```

This design avoids ambiguous heuristics and ensures transparent behavior.

### **4. Fully Planner-Safe**

The contract avoids unsafe assumptions by systematically checking:

* `data.length >= 2`
* `data[0].length > 0`, `data[1].length > 0`
* proper decoding boundaries

This is required for safe multi-operator deployment.

---

## **How the Trap Works**

### **1. Data Collection Stage**

`collect()` is called by the Drosera relay every block (or according to the configured sample rate).
It returns:

* the current basefee
* the current block number

Encoded as:

```
abi.encode(basefee, block.number)
```

This becomes the next sample in the Drosera sample ring.

---

### **2. Evaluation Stage**

`shouldRespond(bytes[] calldata data)` receives the last two samples:

* `data[0]` → newest block
* `data[1]` → previous block

The trap performs:

1. Safety checks
2. Decoding of both samples
3. Threshold comparison

If conditions match, the trap returns:

```
(true, data[0])
```

The payload `data[0]` becomes the input to the response contract.

---

### **3. Response Execution Stage**

The responder contract (`ResponseBasefee.sol`) receives the payload and decodes:

* previous basefee
* previous block
* current basefee
* current block

It then emits an event summarizing the spike, enabling off-chain indexing tools or researchers to track localized surges in basefee.

No state is stored, and no additional logic is executed to maintain predictable behavior.

---

## **Use Case**

A trap like this is useful for:

* monitoring congestion
* triggering automated alerts
* examining abnormal basefee behavior
* detecting MEV-induced demand spikes
* reacting programmatically to fee pressure

This PoC serves as a foundation that can expand into more advanced fee-response strategies like:

* statistical anomaly detection
* rolling-window basefee volatility analysis
* threshold adaptation

---

## **Deployment Summary**

Your contracts have been successfully deployed on the Hoodi Testnet.

### **Contract Addresses**

| Contract             | Address                                      |
| -------------------- | -------------------------------------------- |
| **ResponseBasefee**  | `0x7eDBCA1450f90F1927cb5721302a209D1e109fc9` |
| **BasefeeSurgeTrap** | `0xe5443D5CD2AeBB6930FaC46aA440D847d92A7584` |

---

## **Network Configuration**

**Chain:** Hoodi Testnet
**Chain ID:** `560048`
**Ethereum RPC:** `https://ethereum-hoodi-rpc.publicnode.com`
**Drosera Relay:** `https://relay.hoodi.drosera.io`

---

## **drosera.toml (Ready for Operator Use)**

```toml
ethereum_rpc   = "https://ethereum-hoodi-rpc.publicnode.com"
drosera_rpc    = "https://relay.hoodi.drosera.io"
eth_chain_id   = 560048
drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"

[traps]

[traps.basefee_surge]
path = "out/BasefeeSurgeTrap.sol/BasefeeSurgeTrap.json"
response_contract = "0x7eDBCA1450f90F1927cb5721302a209D1e109fc9"
response_function = "respondToBasefee(uint256,uint256)"
block_sample_size = 2
cooldown_period_blocks = 20
private_trap = true
whitelist = ["0x8b75540D19629C135D2822EEfb124838AC0b0f68"]
```

This configuration adheres exactly to the formatting and structure expected by Drosera moderators.

---

## **Running the Trap**

### **1. Start the Drosera node**

```bash
drosera node
```

### **2. Run the operator for this trap**

```bash
drosera operator --trap basefee_surge
```

The relay will now:

* collect new basefee samples
* pass them into your trap
* evaluate the threshold logic
* automatically call your responder when triggered

---

## **Repository Structure**

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

Each file has a clear responsibility and maintains separation of concerns.

---

## **Safety & Reliability Notes**

This trap follows Drosera best practices:

* **no storage writes**
* **no dynamic state mutation**
* **no unsafe external calls**
* **predictable, fully deterministic behavior**
* **planner-safe array and payload checks**
* **relay-friendly logic flow**
* **compatible with private trap whitelisting**

These properties make it suitable for evaluation for higher Drosera roles (Sergeant, Captain, Janissary Hero, etc).

---

## **Acknowledgements**

Special thanks to the Drosera review team for building a clear ecosystem around modular trap development. This PoC follows patterns gathered from the official examples, Janissary traps, and feedback shared within the Trappers’ Path.

---
