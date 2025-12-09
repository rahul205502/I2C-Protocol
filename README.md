## 💾 README.md: Verilog I²C Master Controller

# 🚀 Verilog I²C Master Controller (Single Write Transaction)

[cite_start]This repository contains the Verilog implementation of a basic **$I^2C$ (Inter-Integrated Circuit) Master controller**[cite: 388]. [cite_start]This controller is designed to execute a **single-byte write transaction** to a slave device, managing all aspects of the protocol, including clock generation, START/STOP conditions, addressing, data transfer, and ACK handling[cite: 389].

---

## ✨ Features and Design Overview

[cite_start]The master controller (`I2C_1.v`) performs a full write operation: **START $\rightarrow$ ADDRESS + W $\rightarrow$ ACK $\rightarrow$ DATA $\rightarrow$ ACK $\rightarrow$ STOP**[cite: 426].

* [cite_start]**Two-Wire Protocol:** Implements control for the two bus lines: **SCL (Serial Clock)** and **SDA (Serial Data)**[cite: 393].
* [cite_start]**Open-Drain Logic:** Models the open-drain nature of the SDA line using a tristate buffer for switching between driving the line (`1'b0`) and releasing it (`1'bz`)[cite: 407, 408, 411, 412].
    * [cite_start]The master logic uses `i2c_sda_en` to control the tristate buffer[cite: 447, 449].
    * `assign SDA = i2c_sda_en ? [cite_start]1'bz : i2c_sda;` [cite: 820]
* [cite_start]**Clock Generation:** Generates the SCL signal by dividing the high-frequency system clock (CLK)[cite: 414].
    * [cite_start]**Division Factor:** `localparam SCL_DIV_COUNT = 250;` [cite: 417, 471, 825]
    * [cite_start]**SCL Frequency:** Assuming $f_{CLK} = 50$ MHz, the resulting $f_{SCL}$ is **100 kHz** (I²C Standard Mode speed)[cite: 418, 419, 420].
* [cite_start]**FSM Control:** A Finite State Machine (FSM) manages the complete transaction sequence[cite: 421]. 

---

## 🏗️ Project Structure

| File | Description |
| :--- | :--- |
| `I2C.v` | [cite_start]The main Verilog module implementing the I²C Master FSM and clock generation[cite: 401]. |
| `I2C_1tb.v` | [cite_start]The Verilog testbench used for simulation, including the SDA pull-up model and a simple slave ACK model[cite: 692, 693]. |

---

## 📌 Module Interface (`I2C_1.v`)

| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `CLK` | Input | 1 | [cite_start]System Clock (High Frequency) [cite: 405] |
| `RST` | Input | 1 | [cite_start]Asynchronous Reset (Active High) [cite: 405] |
| `data_in` | Input | 8 | [cite_start]8-bit Data to be written [cite: 405] |
| `addr_in` | Input | 7 | [cite_start]7-bit Slave Address [cite: 405] |
| `SDA` | Inout | 1 | [cite_start]Bi-directional Serial Data Line [cite: 405] |
| `SCL` | Output | 1 | [cite_start]Serial Clock Line [cite: 405] |

---

## 🧠 FSM States and Actions

[cite_start]The FSM transitions on the falling edge of the divided SCL clock (when `scl_count = 0`)[cite: 422, 530].

| State Name | Value | Action / Description |
| :--- | :--- | :--- |
| `IDLE` | 0 | Wait for transaction start. [cite_start]SCL/SDA are high[cite: 424]. |
| `START` | 1 | [cite_start]Generates the **START Condition** (SDA $1\rightarrow0$ while SCL is 1)[cite: 424, 551, 552]. |
| `ADDR` | 2 | [cite_start]Transmits the **7-bit slave address** followed by the Write bit (0)[cite: 424, 556, 557]. |
| `ACK_WAIT1` | 3 | [cite_start]Releases SDA (`1'bz`) and checks for **Slave ACK** (SDA 0)[cite: 424, 599]. |
| `DATA` | 4 | [cite_start]Transmits the **8-bit data byte**[cite: 424]. |
| `ACK_WAIT2` | 5 | [cite_start]Releases SDA (`1'bz`) and checks for **Slave ACK** (SDA 0)[cite: 424, 647]. |
| `STOP` | 6 | [cite_start]Generates the **STOP Condition** (SDA $0\rightarrow1$ while SCL is 1)[cite: 424, 667, 668, 660, 662]. |

---

## 🧪 Simulation (`I2C_1tb.v`)

[cite_start]The testbench includes models for the external bus components[cite: 694].

1.  [cite_start]**SDA Pull-up Model:** The Verilog primitive `pullup (SDA)` is used to model the open-drain nature of the bus[cite: 696].
2.  [cite_start]**Simple Slave ACK Model:** The slave model drives SDA low to generate an ACK when the master is in `ACK_WAIT1` (State 3) or `ACK_WAIT2` (State 5)[cite: 700].

### Test Scenario
* [cite_start]**High-Speed Clock:** CLK is generated with a **20 ns period** (50 MHz)[cite: 695, 379].
* [cite_start]**Slave Address:** `addr_in = 7'h50` [cite: 704, 380]
* [cite_start]**Data to Write:** `data_in = 8'hAA` [cite: 705, 380]
* [cite_start]**Duration:** The simulation runs for **192000 ns** to cover the full transaction at 100 kHz speed[cite: 706, 381].
