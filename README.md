# Synchronous FIFO — SVA-Based Verification

A SystemVerilog verification project for an **8-bit synchronous FIFO with depth 8**, verified using SystemVerilog Assertions (SVA), functional coverage, directed corner-case testing, Verilator, and GTKWave.

---

## 1. Project Overview

This project implements and verifies a parameterized synchronous FIFO.

### DUT Configuration

| Parameter | Value |
|---|---:|
| Data Width | 8 bits |
| FIFO Depth | 8 |
| Count Width | `$clog2(DEPTH + 1)` |
| Clock | Synchronous |
| Reset | Active-low |
| Verification | SystemVerilog |
| Simulator | Verilator |
| Waveform Viewer | GTKWave |

The FIFO provides:

- Write operation
- Read operation
- Empty indication
- Full indication
- Occupancy/count monitoring
- Protection against write when full
- Protection against read when empty
- Simultaneous read/write operation

---

## 2. Repository Structure

```text
sva_fifo_verification/
│
├── assertions/
│   └── fifo_sva.sv
│
├── coverage/
│   └── fifo_coverage.sv
│
├── rtl/
│   └── sync_fifo.sv
│
├── scripts/
│
├── tb/
│   └── fifo_tb.sv
│
├── tests/
│
├── waves/
│
├── bugs/
│
├── Makefile
├── README.md
└── .gitignore
```

### Directory Description

| Directory/File | Purpose |
|---|---|
| `rtl/` | FIFO RTL design |
| `assertions/` | SystemVerilog assertion properties |
| `coverage/` | Functional coverage model |
| `tb/` | Top-level testbench |
| `tests/` | Additional test material |
| `scripts/` | Simulation/helper scripts |
| `waves/` | Generated waveform files |
| `bugs/` | Bug/debugging experiments |
| `Makefile` | Build and simulation automation |
| `README.md` | Project documentation |

Generated files such as Verilator build products and waveform files are excluded through `.gitignore`.

---

## 3. FIFO Interface

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Active-low reset |
| `wr_en` | Input | Write enable |
| `rd_en` | Input | Read enable |
| `wr_data` | Input | Write data |
| `rd_data` | Output | Read data |
| `empty` | Output | FIFO empty indication |
| `full` | Output | FIFO full indication |
| `count_dbg` | Output | FIFO occupancy |

---

## 4. Verification Strategy

The verification environment combines:

### 4.1 Directed Functional Testing

The testbench exercises:

1. Reset behavior
2. FIFO writes
3. FIFO full condition
4. FIFO reads
5. FIFO empty condition
6. Write after empty
7. Read after write
8. Write while full
9. Simultaneous read/write
10. Read while empty
11. Final FIFO state

FIFO ordering is checked by writing known values and verifying that they are subsequently read in the same order.

---

## 5. SystemVerilog Assertions

The assertion module monitors FIFO behavior independently of stimulus generation.

The verification intent includes checks related to:

- Reset state
- Empty condition
- Full condition
- FIFO occupancy
- Legal read/write behavior
- Boundary conditions
- State transitions
- FIFO count consistency

Assertions are compiled using Verilator assertion support.

---

## 6. Functional Coverage

The coverage model monitors important FIFO operating conditions:

- Write transactions
- Read transactions
- Simultaneous read/write
- EMPTY state
- FULL state
- PARTIAL occupancy
- `COUNT = 0`
- `COUNT = 1`
- Intermediate occupancy
- `COUNT = DEPTH - 1`
- `COUNT = DEPTH`
- Write while FULL
- Read while EMPTY
- EMPTY → NONEMPTY
- NONEMPTY → EMPTY
- NONFULL → FULL
- FULL → NONFULL

### Observed Coverage Activity

| Coverage Item | Observed |
|---|---:|
| Writes | 19 |
| Reads | 19 |
| Simultaneous RD + WR | 1 |
| EMPTY | 10 |
| FULL | 5 |
| PARTIAL | 60 |
| COUNT = 0 | 10 |
| COUNT = 1 | 10 |
| COUNT = MID | 40 |
| COUNT = DEPTH − 1 | 10 |
| COUNT = DEPTH | 5 |
| WRITE while FULL | 1 |
| READ while EMPTY | 1 |
| EMPTY → NONEMPTY | 3 |
| NONEMPTY → EMPTY | 3 |
| NONFULL → FULL | 2 |
| FULL → NONFULL | 2 |
| Total sampled cycles | 75 |
| Reset cycles | 1 |

---

## 7. Test Sequence

### Test 1 — Reset

Expected:

```text
empty = 1
full  = 0
count = 0
```

### Test 2 — Write 8 Values

Eight values are written:

```text
1, 2, 3, 4, 5, 6, 7, 8
```

### Test 3 — Full Condition

After eight successful writes:

```text
empty = 0
full  = 1
count = 8
```

### Test 4 — Read 8 Values

The stored values are read and checked in FIFO order:

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
```

### Test 5 — Empty Condition

After all eight values are consumed:

```text
empty = 1
full  = 0
count = 0
```

### Test 6 — Write After Empty

The value `0xA5` is written into the empty FIFO.

Expected:

```text
count = 1
```

### Test 7 — Read After Write

Expected read value:

```text
0xA5
```

### Test 8 — Coverage-Directed Corner Cases

The testbench exercises:

- FIFO full boundary
- Write while full
- Simultaneous read/write
- FIFO empty boundary
- Read while empty

---

## 8. Simulation Using Verilator

Run from the project root.

### Compile

```bash
verilator --binary --timing --trace --assert \
--top-module fifo_tb \
-Wno-WIDTH \
rtl/sync_fifo.sv \
assertions/fifo_sva.sv \
coverage/fifo_coverage.sv \
tb/fifo_tb.sv
```

### Run

```bash
./obj_dir/Vfifo_tb
```

The simulation generates:

```text
waves/fifo.vcd
```

---

## 9. Waveform Analysis

Open the waveform with:

```bash
gtkwave waves/fifo.vcd
```

Important signals:

```text
clk
rst_n
wr_en
rd_en
wr_data
rd_data
empty
full
count_dbg
```

The waveform can be used to inspect reset behavior, writes, reads, occupancy, full/empty transitions, simultaneous read/write, and boundary conditions.

---

## 10. Expected Verification Result

A successful verification run should complete without FIFO test failures or assertion failures and reach the final empty state:

```text
empty = 1
full  = 0
count = 0
```

Verification environment:

```text
Verilator 5.032
SystemVerilog Assertions
Functional Coverage
GTKWave
```

---

## 11. Verification Flow

```text
              ┌─────────────────────┐
              │   FIFO RTL Design   │
              │   sync_fifo.sv      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │     Testbench       │
              │     fifo_tb.sv      │
              └──────────┬──────────┘
                         │
             ┌───────────┼───────────┐
             ▼           ▼           ▼
      ┌────────────┐ ┌──────────┐ ┌──────────────┐
      │    SVA     │ │ Coverage │ │   Directed   │
      │ Assertions │ │  Model   │ │    Tests     │
      └─────┬──────┘ └────┬─────┘ └──────┬───────┘
            │             │              │
            └─────────────┼──────────────┘
                          ▼
                 ┌────────────────┐
                 │    Verilator   │
                 └───────┬────────┘
                         │
                         ▼
                 ┌────────────────┐
                 │   Simulation   │
                 └───────┬────────┘
                         │
                         ▼
                 ┌────────────────┐
                 │   fifo.vcd     │
                 └───────┬────────┘
                         │
                         ▼
                    ┌──────────┐
                    │ GTKWave  │
                    └──────────┘
```

---

## 12. Technologies Used

- SystemVerilog
- SystemVerilog Assertions (SVA)
- Verilator
- GTKWave
- Make
- Linux / WSL
- Git
- GitHub
- Visual Studio Code

---

## 13. Learning Objectives

This project demonstrates practical experience with:

- RTL FIFO design
- Parameterized SystemVerilog
- Synchronous digital design
- SystemVerilog Assertions
- Functional coverage
- Directed verification
- Corner-case verification
- Waveform debugging
- Verilator-based simulation
- Git/GitHub project management

---

## 14. Author

**Suresh Kumar**

M.Tech — Systems & Control Engineering  
IIT Bombay

GitHub:  
https://github.com/suresh-vlsi
