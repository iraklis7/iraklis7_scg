# UART IP Core Specification v0.7 Delta Analysis Report

**Document Version:** Rev. 0.7 (March 2, 2026) vs Rev. 0.6 (August 11, 2002)  
**Specification:** UART16550 IP Core Specification  
**Author:** Jacob Gorban (Original), Iraklis (v0.7 Updates)

---

## 1. Specification Overview

### UART IP Core Specification v0.7

The UART (Universal Asynchronous Receiver/Transmitter) IP core provides serial communication capabilities for interfacing with modems or external devices using RS232 protocol. The design targets maximal compatibility with the industry-standard National Semiconductors 16550A device.

**Key Features:**
- **WISHBONE Interface:** Supports both 32-bit and 8-bit data bus modes (selectable)
- **FIFO-Only Operation:** Enhanced buffering for both transmit and receive paths
- **NS16550A Compatibility:** Register-level and functional compatibility (excluding 16450 mode)
- **Debug Interface:** Available in 32-bit data bus mode with two 32-bit debug registers
- **Configurable Sampling:** Variable-sized sliding sampler for enhanced noise immunity (NEW in v0.7)
- **Baud Rate Output:** Optional 16x baud rate output signal (BAUD_O)

**Core Capabilities:**
- Supports 5, 6, 7, or 8-bit character lengths
- Configurable parity (none, odd, even, stick)
- 1, 1.5, or 2 stop bits
- Programmable baud rate via 16-bit divisor latch
- Four interrupt types with priority handling
- Loopback mode for testing
- Full modem control signals (RTS, CTS, DTR, DSR, RI, DCD)

---

## 2. New Features

### 2.1 Variable-Sized Sliding Sampler (Sampling Control Register - SCR)

#### Description

The v0.7 specification introduces a new **Sampling Control Register (SCR)** that enables configurable sampling of the serial input data signal. This feature provides a variable-sized sliding sampler window that applies to all data bits in the data frame, including the start bit and stop bit(s).

The sampler operates by:
1. Starting at a configurable sample position (samples 5-8 out of 16 total samples per bit)
2. Collecting a configurable number of consecutive samples (1, 3, 5, or 6 samples)
3. Processing the collected samples through a majority voting function to derive the final bit value

This approach enhances noise immunity and allows fine-tuning of the sampling strategy based on the quality of the serial link and timing characteristics of the communication channel.

#### Functional Details

**Register Address:** Not explicitly stated in v0.7 specification (address mapping to be determined)  
**Register Width:** 8 bits  
**Access Type:** Read/Write (RW)  
**Reset Value:** 00000000b (default: sample at position 8, collect 1 sample)

**Bit Field Definitions:**

| Bits | Access | Function | Values |
|------|--------|----------|--------|
| 1-0  | RW     | Select beginning of sampler window | '00' – Sample 8 (middle of 16 samples)<br>'01' – Sample 7<br>'10' – Sample 6<br>'11' – Sample 5 |
| 3-2  | RW     | Specify number of samples to collect | '00' – 1 sample<br>'01' – 3 samples<br>'10' – 5 samples<br>'11' – 6 samples |
| 7-4  | R      | Ignored | Reserved |

#### Specification References

- **Section 4.6:** "Sampling Control Register (SCR)" - Complete register definition including bit fields, access modes, and reset value
- **Section 4.6, Paragraph 1:** "The sampling control register allows the specification of a variable slinging sampler of the data signal and applies to all data bits in the data frame, including the start bit and stop bit(s)."
- **Section 4.6, Paragraph 2:** "The device starts sampling on the sample defined by the first two bits of the SCR and collects as many smaples are defined by the next two bits. The resulting samples are then passed through a majority voting function, in order to derive the overall sample value."
- **Section 5.1 (Initialization), Bullet 5:** "The Sampling Control Register is set to sample at the 8th sample, for 1 sample." - Describes reset behavior
- **Section 5.1 (Initialization), Bullet 7:** "Set the Sampling Control Register to the desired value." - Added to initialization procedure
- **Figure 1 (Block Diagram):** Updated architecture diagram now shows "Sampling Control Register" as a new block connected to the "Receiver logic w/ sampler" block

#### Impact on Complexity

**Design Complexity:**
- **RTL Implementation:** MINOR to MODERATE
  - Requires modification of the receiver sampling logic
  - Addition of new 8-bit register with decode logic
  - Implementation of configurable sample window selector
  - Implementation of majority voting function for multi-sample acquisition
  - Minimal impact on existing data path; primarily affects receiver sampling circuitry

**Verification Complexity:**
- **UVM Environment:** MINOR to MODERATE
  - New register model for SCR must be added to RAL (Register Abstraction Layer)
  - Register access sequences need to be updated
  - New sampling configuration scenarios need to be tested
  - Verification of majority voting logic under various noise conditions
  - Corner case testing: minimum samples (1), maximum samples (6), early/late sampling positions
  - Compatibility testing to ensure default behavior matches v0.6 (sample 8, 1 sample)

**Development Effort Rating:** **MINOR**

The feature is relatively self-contained and affects primarily the receiver sampling logic. The register interface follows existing patterns, and the functionality is well-defined. However, thorough verification of all sampling configurations and their interaction with different baud rates, character formats, and noise conditions will be necessary.

---

## 3. Conclusion

### Overall Complexity Assessment

The UART IP Core Specification v0.7 represents a **minor evolutionary update** from v0.6, with the addition of a single new feature: the Sampling Control Register (SCR) for variable-sized sliding sampler configuration.

### Complexity Comparison: v0.7 vs v0.6

**Specification Scope:**
- **Core Functionality:** Unchanged - all fundamental UART operations remain identical
- **Register Count:** Increased from 10 to 11 registers (addition of SCR)
- **Interface Signals:** Unchanged - all I/O ports remain the same
- **Architecture:** Minimal modification - only receiver sampling block is affected

**Functional Enhancements:**
- The new SCR provides enhanced flexibility for noise immunity and timing margin optimization
- Default reset behavior maintains backward compatibility with v0.6
- No breaking changes to existing register definitions or behaviors

### Impact on RTL Development

**Estimated Effort:** Low to Moderate

**RTL Changes Required:**
1. **New Register Implementation:**
   - Add SCR register at appropriate address (address not specified in v0.7 - requires clarification)
   - Implement register decode logic
   - Implement read/write functionality with proper reset value

2. **Receiver Sampling Logic Modification:**
   - Modify bit sampler to use configurable sample start position (instead of fixed sample 8)
   - Implement configurable sample collection (1, 3, 5, or 6 samples)
   - Implement majority voting logic for multi-sample scenarios
   - Ensure proper handling of all 16 combinations of sample position and count

3. **Integration:**
   - Connect SCR outputs to receiver sampling block
   - Update architecture block diagram to reflect new register
   - Ensure no timing impact on critical paths

**Estimated RTL Effort:** 2-3 weeks for experienced RTL engineer, including:
- Design and coding: 1 week
- Self-verification and debugging: 1 week
- Integration and timing closure: 0.5-1 week

### Impact on UVM Verification Environment

**Estimated Effort:** Moderate

**UVM Environment Updates Required:**
1. **Register Model:**
   - Add SCR to RAL model with proper field definitions
   - Update address map (pending address assignment clarification)
   - Update register predictor and monitor

2. **Sequences:**
   - Create SCR configuration sequences
   - Update existing initialization sequences to include SCR setup
   - Create sequences to test all SCR configurations (16 combinations)

3. **Test Scenarios:**
   - **Register Access Tests:**
     - Read/write SCR at different times (before/during/after transmission)
     - Reset value verification
     - Reserved bit behavior (bits 7-4)
   
   - **Functional Tests:**
     - Default configuration (sample 8, 1 sample) - backward compatibility
     - All 4 sample start positions × 4 sample counts = 16 configurations
     - Sampling with different baud rates and clock frequencies
     - Sampling with injected noise (if supported by testbench)
     - Edge cases: earliest sample position (5) with maximum samples (6)
     - Majority voting verification: 3-sample, 5-sample, 6-sample with varying input patterns
   
   - **Coverage:**
     - SCR field coverage for all valid combinations
     - Cross-coverage: SCR settings × baud rates × character formats
     - Functional coverage for majority voting outcomes

4. **Scoreboards and Checkers:**
   - Update receiver checker to account for configurable sampling
   - Verify correct bit interpretation based on SCR settings
   - Monitor for any unexpected behavior during SCR changes

**Estimated UVM Effort:** 3-4 weeks for experienced verification engineer, including:
- RAL model updates: 0.5 week
- Sequence development: 1 week
- Test scenario implementation: 1.5-2 weeks
- Debug and coverage closure: 1 week

### Overall Development Timeline Estimate

Assuming parallel RTL and verification work:
- **RTL Development + Unit Testing:** 2-3 weeks
- **UVM Environment Updates:** 3-4 weeks
- **Integration and Regression:** 1-2 weeks
- **Total Project Duration:** Approximately 4-6 weeks

### Risks and Considerations

1. **Address Assignment:** The v0.7 specification does not explicitly state the address for the SCR register. This must be clarified before implementation. Suggested address could be 7 (currently unassigned in the standard register map).

2. **Backward Compatibility:** The default reset value (sample 8, 1 sample) ensures that devices configured with default settings will behave identically to v0.6. This is critical for drop-in replacement scenarios.

3. **Timing Impact:** The majority voting logic and configurable sample mux may impact receiver timing. Careful attention should be paid to:
   - Setup/hold times on the sample selection signals
   - Propagation delay through the majority voting combinational logic
   - Impact on receiver FSM state machine timing

4. **Corner Cases:** Special attention needed for:
   - Sample position 5 + 6 samples = samples 5-10 (out of 16 total)
   - Sample position 8 + 6 samples = samples 8-13 (asymmetric around bit center)
   - Interaction with very high baud rates where sample period is short

5. **Documentation:** The v0.7 specification contains a typographical error ("slinging sampler" should likely be "sliding sampler"). Implementation should follow the intended sliding window behavior.

### Recommendations

1. **Clarify SCR Address:** Request specification update to explicitly define SCR register address
2. **Enhanced Testing:** Given the noise immunity objective, consider adding noise injection capability to the testbench if not already present
3. **Performance Characterization:** Conduct measurements or simulations to characterize bit error rate (BER) improvement with different SCR configurations under various noise conditions
4. **Documentation:** Update user documentation to provide guidance on optimal SCR settings for different application scenarios (e.g., noisy industrial environments vs. clean PCB traces)
5. **Regression Testing:** Ensure all existing v0.6 test cases pass with SCR at default reset value to validate backward compatibility

---

**Report Generated:** March 2, 2026  
**Prepared By:** Technical Lead - Design Verification  
**Status:** Final
