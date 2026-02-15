# UART 16550 Specification Delta Report
## Version 0.6 vs Version 0.5b

---

## 1. Specification Overview

**Latest Specification:** UART IP Core Specification, Rev. 0.6, August 11, 2002

The UART 0.6 specification describes a UART16550 IP core providing serial communication capabilities with RS232 protocol compatibility. This core is designed for maximum compatibility with the industry standard National Semiconductors' 16550A device. The core features a WISHBONE interface (32-bit or 8-bit selectable), FIFO-only operation, register-level functionality compatibility with NS16550A, and a debug interface in 32-bit mode. 

**Key characteristics:** The core operates at clock rates ranging from 1.258 MHz (for 1200 bps) to 3.6864 MHz (for 115200 bps), implements eight main control/status registers, includes two 16-bit divisor latch registers for baud rate control, and provides support for modem control signals (RTS, DTR, CTS, DSR, RI, DCD).

---

## 2. New Features

### 2.1 Parity Feature Implementation

**Description:** The specification now includes full support for parity bit generation, transmission, and error detection capabilities. This represents a significant enhancement to the communication reliability features of the UART core. The previous version (0.5b) had parity control bits marked as "reserved" and unavailable. Version 0.6 implements three distinct parity control mechanisms:

1. **Parity Enable Control** - Allows enabling/disabling parity on each character
2. **Parity Type Selection** - Supports both odd and even parity modes with separate control
3. **Stick Parity** - Advanced parity feature for special testing or forced parity states

**Specification References:**

- **Line Control Register (LCR) Bit 3 - Parity Enable:**
  - Section 4.5, LCR definition, Bit 3 (RW access)
  - Previous version: Read-only ('0' - No parity bit. Feature unavailable in this version)
  - Current version: Read-Write, allows parity bit generation on outgoing characters and checking on incoming ones
  - Location: UART_0.6_delta_0.5b_report.md reference point 821-824

- **Line Control Register (LCR) Bit 4 - Even Parity Select:**
  - Section 4.5, LCR definition, Bit 4 (RW access)
  - Previous version: Read-only, Reserved
  - Current version: Read-Write, selects between odd parity ('0') and even parity ('1')
  - Detailed behavior: "Odd number of '1' is transmitted and checked in each word (data and parity combined). In other words, if the data has an even number of '1' in it, then the parity bit is '1'."
  - Location: UART specification Section 4.5, page 9-10

- **Line Control Register (LCR) Bit 5 - Stick Parity:**
  - Section 4.5, LCR definition, Bit 5 (RW access)
  - Previous version: Read-only, Reserved
  - Current version: Read-Write, enables stick parity feature
  - Behavior: When bits 3 and 4 are both '1', parity bit is transmitted and checked as logic '0'. When bit 3 is '1' and bit 4 is '0', parity bit is transmitted and checked as '1'.
  - Location: UART specification Section 4.5, page 9

- **Parity Error Indication (LSR Bit 2):**
  - Section 4.7, Line Status Register (LSR), Bit 2
  - Previous version: Simple statement "'0' – No parity error in the current character"
  - Current version: Expanded to include detection behavior: "'1' – The character that is currently at the top of the FIFO has been received with parity error. The bit is cleared upon reading from the register. Generates Receiver Line Status interrupt."
  - Location: UART specification Section 4.7, page 11-12

- **Error Indication (LSR Bit 7) - Updated:**
  - Section 4.7, Line Status Register (LSR), Bit 7
  - Previous version: "'1' – At least one framing error or break indications have been received and are inside the FIFO."
  - Current version: "'1' – At least one parity error, framing error or break indications have been received and are inside the FIFO."
  - Impact: The error accumulator now tracks parity errors in addition to framing and break errors
  - Location: UART specification Section 4.7, page 12

- **Interrupt Identification Table Update:**
  - Section 4.3, Interrupt Identification Register (IIR)
  - Bit 3,2,1 = 0,1,1 (1st priority): Receiver Line Status interrupt source now includes parity errors
  - Previous version: "Overrun or Framing errors or Break Interrupt"
  - Current version: "Parity, Overrun or Framing errors or Break Interrupt"
  - Location: UART specification Section 4.3, Table showing interrupt types, page 7

- **Initialization Sequence Update:**
  - Section 5.1, Initialization
  - Line Control Register reset value now explicitly states: "The Line Control Register is set to communication of 8 bits of data, no parity, 1 stop bit."
  - Previous version: "The Line Control Register is set to communication of 8 bits of data, 1 stop bit." (parity state not explicitly mentioned)
  - This clarifies that parity is disabled by default at reset
  - Location: UART specification Section 5.1, Initialization, page 16

- **Break Interval Timing Clarification:**
  - Section 4.7, Line Status Register (LSR), Bit 4 description
  - The break condition timing now explicitly includes parity bit in the character timing: "The break occurs when the line is held in logic 0 for a time of one character (start bit + data + parity + stop bit)."
  - Previous version: "The break occurs when the line is held in logic 0 for a time of one character (start bit + data + stop bit)."
  - This change indicates that parity timing is now a formal part of the character period calculation
  - Location: UART specification Section 4.7, page 11

**Impact on Complexity:**

The addition of parity feature support introduces moderate complexity to the specification:

- **Register Control Complexity:** The LCR register now includes three functional control bits (3, 4, 5) instead of two reserved bits. This requires additional control logic to manage parity generation and checking.
- **Error Detection Logic:** Parity error detection must be integrated into the receiver path, with proper flagging in both the LSR register and interrupt generation logic.
- **Transmitter Enhancement:** The transmitter must calculate and insert parity bits based on LCR[3:5] configuration for each outgoing character.
- **Initialization Handling:** The reset behavior now explicitly defines parity to be disabled, requiring verification in implementation.
- **Interrupt Priority:** The IIR must incorporate parity errors as a detectable interrupt condition at the same priority level as other line status errors.

**Development Effort Rating:** **Major**

The parity feature requires:
- Implementation of parity generation algorithms (odd/even/stick parity)
- Integration of parity error detection in the receiver chain
- Extension of the LSR and interrupt logic to track parity errors
- Verification of parity calculation across various data formats (5-8 bit characters)
- Testing of stick parity edge cases

---

## 3. Conclusion

### Complexity Assessment

The UART specification version 0.6 increases in functional complexity compared to version 0.5b primarily due to the addition of full parity support. While the overall architecture, FIFO organization, and WISHBONE interface remain unchanged, the addition of parity feature extends the data path control and error detection capabilities.

**Complexity Delta:** The change represents an **increase from 2 reserved bits in LCR to 3 fully functional parity control bits**, along with expanded error detection and tracking. The specification maintains backward compatibility at the structural level (no register reorganization), but requires new functional logic for parity handling.

### Impact on RTL Development

**Expected Effort: Major**

1. **Transmitter Path Changes:**
   - Add parity generation FSM/combinational logic
   - Modify transmitter shift register to insert parity bit at correct position
   - Update transmitter to respect LCR[3:5] parity configuration
   - Estimated implementation: 200-300 lines of new RTL code

2. **Receiver Path Changes:**
   - Add parity check logic in the receiver path
   - Integrate parity error detection with LSR[2] flag
   - Update error accumulation logic for LSR[7]
   - Estimated implementation: 150-250 lines of new RTL code

3. **Control Logic Updates:**
   - Modify LCR register to enable writing to bits [5:3]
   - Update interrupt generation logic to include parity errors in IIR
   - Estimated implementation: 50-100 lines

4. **Verification Implications:**
   - All existing character format tests must be re-verified with parity enabled/disabled
   - New parity error injection scenarios required
   - Stick parity edge cases need specific test coverage
   - Initialization sequence tests must verify parity is disabled by default

**Total Estimated Code Impact:** 400-650 lines of new RTL code plus comprehensive test scenarios

### Impact on UVM Verification Environment

**Expected Effort: Major**

1. **Test Plan Expansion:**
   - New sequences for parity enable/disable modes
   - Odd vs. even parity verification sequences
   - Stick parity edge case sequences
   - Parity error injection and detection scenarios
   - Combined parity + other errors (framing, overrun) test scenarios

2. **Scoreboarding Enhancements:**
   - Parity calculation added to expected value prediction
   - Parity error injection in driver/monitor
   - LSR bit tracking expanded to include parity errors
   - IIR interrupt priority verification for parity errors

3. **Coverage Model Additions:**
   - Parity generation coverage (all data patterns, 5-8 bit modes)
   - Parity error detection coverage (correct and false positives)
   - LCR configuration coverage (all combinations of bits [5:3])
   - Initialization coverage (verify parity disabled at reset)

4. **Test Case Volume:**
   - Estimated 20-30 new parity-specific test cases
   - Estimated 15-20 combined feature test cases (parity with other functions)
   - Regression suite requires expansion to maintain coverage metrics

**Verification Complexity:** The addition of parity introduces a new data transformation layer that must be comprehensively verified across all character formats, all error conditions, and all timing scenarios. The feature is relatively independent (does not affect FIFO structure or timing), making verification tractable but requiring careful attention to error injection and edge cases.

### Overall Specification Maturity

**Transition from 0.5b to 0.6:** This specification update represents the addition of a significant feature rather than architectural redesign. The parity feature is now a first-class function of the UART core, transitioning from "unavailable" to "fully supported with three control modes." This brings the core closer to full NS16550A compatibility, as the 16550A does support parity modes.

**Recommendation:** Development teams should prioritize the parity feature as a significant work item with its own test infrastructure, implementation phases, and verification milestones. The feature should be integrated incrementally (odd/even parity first, then stick parity) to manage complexity and enable staged verification.

---

## Revision Summary

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.5b | 10/08/02 | Jacob Gorban | Added optional BAUD_O output |
| 0.6 | 11/08/02 | Jacob Gorban | **Added parity feature implementation** |

