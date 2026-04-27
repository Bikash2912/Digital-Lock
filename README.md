# 🔐 FPGA-Based Secure Digital Lock System (Basys3)

## 📌 Overview

This project implements a **hardware-level secure digital lock system** on the **Digilent Basys3 FPGA (Artix-7)** using **pure Verilog RTL design**.
Unlike conventional microcontroller-based systems, this design eliminates firmware vulnerabilities by enforcing all authentication logic directly in hardware.

The system integrates keypad input, password hashing, authentication control, and multiple output interfaces including LCD, 7-segment display, LEDs, and buzzer feedback.

---

## 🧠 Key Features

* **Fully Hardware-Based Security**

  * No firmware or software layer
  * Deterministic execution using RTL logic

* **Secure Password Handling**

  * 16-bit password stored as **hashed value**
  * No plaintext password storage
  * Custom **rotate–XOR–add hash function**

* **Authentication Control**

  * Moore FSM-based system control
  * 4-digit password entry via keypad
  * Separate **SAVE** and **CHECK** modes

* **Fail-Secure Mechanism**

  * Maximum 3 failed attempts
  * Permanent lock until reset
  * Hardware-enforced lockout

* **User Interface**

  * 4×4 matrix keypad input
  * 16x2 LCD (HD44780, 4-bit mode)
  * 4-digit 7-segment display
  * Multi-color LED status indicators
  * Buzzer with pattern-based feedback

* **External Hardware Integration**

  * External push buttons (reset, save, check, mode)
  * Breadboard-compatible control interface

---

## 🏗️ System Architecture

The design follows a **modular hardware architecture**:

### Core Modules

* `keypad_controller.v`
  Scans keypad, debounces input, generates valid pulse

* `password_register.v`
  16-bit shift register for password entry

* `strong_hash.v`
  Combinational hash (rotate–XOR–add)

* `password_storage.v`
  Stores hashed password on save

* `control_unit.v`
  Handles mode selection, entry count, and control signals

* `system_state.v`
  FSM controlling system behavior

* `result_logic` (integrated)
  Compares hash and generates:

  * unlock
  * error
  * locked

---

## 🖥️ Output Modules

* `lcd_parallel.v`
  HD44780 LCD driver (4-bit interface)

* `seg7_display.v`
  Multiplexed 7-segment display driver

* LED Indicators:

  * Unlock status
  * Error indication
  * Save confirmation
  * Mode indication (SAVE / CHECK)

* Buzzer:

  * Different patterns for success / error / lock

---

## 🔁 FSM States

| State  | Description                    |
| ------ | ------------------------------ |
| READY  | System idle                    |
| ENTER  | User entering password         |
| SAVED  | Password successfully stored   |
| OK     | Correct password (unlock)      |
| FAIL   | Incorrect password             |
| LOCKED | System locked after 3 failures |

---

## ⚙️ Hardware Mapping

### Inputs

* Keypad → JA Pmod
* Onboard Buttons → BTNC, BTNU, BTND
* External Buttons → JC Pmod
* Mode Switch → SW0

### Outputs

* LCD → JB Pmod (4-bit mode)
* LEDs → Onboard + External (JC)
* Buzzer → JC Pmod
* 7-Segment Display → Onboard

---

## 🧪 Verification

* Functional verification using **Vivado Simulator**

* Module-wise testbench validation:

  * Keypad scanning
  * Password shifting
  * Hash correctness
  * FSM transitions
  * LCD signal timing

* Hardware validation on Basys3:

  * Correct keypad detection
  * Password save/check operation
  * LCD message display
  * LED and buzzer behavior

---

## 📊 Performance

* Resource Utilization: **<1% LUT usage**
* Fully synchronous design
* Clean timing closure at 100 MHz

---

## 🚧 Challenges Faced

* LCD timing and initialization sequence
* Keypad debouncing and metastability handling
* Multi-source input synchronization (onboard + external)
* Ensuring one-pulse-per-keypress behavior
* Hardware debugging vs simulation mismatch

---

## 🔧 Future Improvements

* EEPROM-based persistent storage
* Multi-user authentication
* UART / Bluetooth interface
* Advanced cryptographic hashing (SHA-based)
* Tamper detection system

---

## 📁 Project Structure

```
/src
  ├── top.v
  ├── keypad_controller.v
  ├── password_register.v
  ├── strong_hash.v
  ├── password_storage.v
  ├── control_unit.v
  ├── system_state.v
  ├── lcd_parallel.v
  ├── seg7_display.v

/sim
  ├── tb_*.v

/constraints
  ├── basys3.xdc
```

---

## 🧾 Conclusion

This project demonstrates how **security-critical systems can be implemented entirely in hardware**, leveraging FPGA parallelism and deterministic control.

By removing software dependencies, the system significantly reduces attack surfaces and improves reliability — making it suitable for embedded security applications.

---

## 🏷️ Tags

FPGA · Verilog · Digital Design · Embedded Systems · Hardware Security · Basys3 · Vivado · RTL Design

---
