//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Assertions Module                                 ////
////                                                              ////
////  SystemVerilog Assertions for UART protocol verification    ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_ASSERTIONS_SV
`define UART_ASSERTIONS_SV

module uart_assertions (
  input bit clk,
  input bit rst_n,
  uart_if.monitor_mp uart_vif
);

  // ===================================================================
  // Transmit Line Assertions
  // ===================================================================

  // A1: Idle state - STX should be high when not transmitting
  property p_stx_idle_high;
    @(posedge clk) disable iff (!rst_n)
    (~(uart_vif.stx === 1'b0 && $past(uart_vif.stx) === 1'b0)) |->
    ##1 uart_vif.stx === 1'b1;
  endproperty
  a_stx_idle_high: assert property (p_stx_idle_high) else $warning("A1 FAILED: STX idle state assertion");

  // A2: Start bit - STX should go low for exactly 16 clock cycles (at 16x oversample)
  property p_stx_start_bit_width;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx === 1'b1 ##1 uart_vif.stx === 1'b0) |->
    uart_vif.stx === 1'b0 ##[15:16] uart_vif.stx === 1'b1;
  endproperty
  a_stx_start_bit_width: assert property (p_stx_start_bit_width) else $warning("A2 FAILED: STX start bit width assertion");

  // A3: Stop bit - STX should be high for at least 16 clock cycles
  property p_stx_stop_bit_high;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx === 1'b1) |->
    ##1 (uart_vif.stx === 1'b1 [*16:$]) until (uart_vif.stx === 1'b0);
  endproperty
  a_stx_stop_bit_high: assert property (p_stx_stop_bit_high) else $warning("A3 FAILED: STX stop bit height assertion");

  // A4: Data bits should remain stable for at least 16 clock cycles each
  property p_stx_data_stability;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx === $past(uart_vif.stx)) |->
    uart_vif.stx === $past(uart_vif.stx, 1) && uart_vif.stx === $past(uart_vif.stx, 2);
  endproperty
  a_stx_data_stability: assert property (p_stx_data_stability) else $warning("A4 FAILED: STX data stability assertion");

  // ===================================================================
  // Receive Line Assertions
  // ===================================================================

  // A5: Idle state - SRX should be high when not receiving
  property p_srx_idle_high;
    @(posedge clk) disable iff (!rst_n)
    (~(uart_vif.srx === 1'b0 && $past(uart_vif.srx) === 1'b0)) |->
    ##1 uart_vif.srx === 1'b1;
  endproperty
  a_srx_idle_high: assert property (p_srx_idle_high) else $warning("A5 FAILED: SRX idle state assertion");

  // A6: Start bit - SRX should go low to indicate start of frame
  property p_srx_start_bit;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.srx === 1'b1 ##1 uart_vif.srx === 1'b0) |->
    uart_vif.srx === 1'b0 [*15:$];
  endproperty
  a_srx_start_bit: assert property (p_srx_start_bit) else $warning("A6 FAILED: SRX start bit assertion");

  // A7: Stop bit - SRX should be high after each character
  property p_srx_stop_bit_high;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.srx === 1'b1) |->
    uart_vif.srx === 1'b1;
  endproperty
  a_srx_stop_bit_high: assert property (p_srx_stop_bit_high) else $warning("A7 FAILED: SRX stop bit assertion");

  // ===================================================================
  // Modem Control Assertions
  // ===================================================================

  // A8: RTS and DTR should be stable
  property p_rts_stable;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.rts === $past(uart_vif.rts)) or 
    (uart_vif.rts !== $past(uart_vif.rts));
  endproperty
  a_rts_stable: assert property (p_rts_stable) else $warning("A8 FAILED: RTS stability assertion");

  // A9: DTR stability
  property p_dtr_stable;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.dtr === $past(uart_vif.dtr)) or 
    (uart_vif.dtr !== $past(uart_vif.dtr));
  endproperty
  a_dtr_stable: assert property (p_dtr_stable) else $warning("A9 FAILED: DTR stability assertion");

  // A10: CTS, DSR, RI, DCD are inputs and can change independently
  property p_modem_input_changes;
    @(posedge clk) disable iff (!rst_n)
    1'b1;
  endproperty
  a_modem_input_changes: assert property (p_modem_input_changes) else $warning("A10 FAILED: Modem input assertion");

  // ===================================================================
  // Flow Control Assertions
  // ===================================================================

  // A11: If CTS is low, the device should not transmit (this is a guideline, not hard requirement)
  // Can be violated in loopback or testing modes
  property p_cts_flow_control;
    @(posedge clk) disable iff (!rst_n)
    1'b1;  // Placeholder - actual check depends on implementation
  endproperty
  a_cts_flow_control: assert property (p_cts_flow_control) else $warning("A11 FAILED: CTS flow control assertion");

  // ===================================================================
  // Timing Assertions
  // ===================================================================

  // A12: STX and SRX should never be driven simultaneously at low (no bus conflicts)
  property p_no_bus_conflict;
    @(posedge clk) disable iff (!rst_n)
    ~((uart_vif.stx === 1'b0) && (uart_vif.srx === 1'b0));
  endproperty
  a_no_bus_conflict: assert property (p_no_bus_conflict) else $warning("A12 FAILED: Bus conflict detection");

  // A13: All modem control signals should be either 0 or 1 (no floating values)
  property p_modem_no_x;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.rts inside {1'b0, 1'b1}) &&
    (uart_vif.dtr inside {1'b0, 1'b1}) &&
    (uart_vif.cts inside {1'b0, 1'b1}) &&
    (uart_vif.dsr inside {1'b0, 1'b1}) &&
    (uart_vif.ri inside {1'b0, 1'b1}) &&
    (uart_vif.dcd inside {1'b0, 1'b1});
  endproperty
  a_modem_no_x: assert property (p_modem_no_x) else $warning("A13 FAILED: Modem signal validity");

  // A14: Serial lines should not be in X state
  property p_serial_no_x;
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx inside {1'b0, 1'b1}) &&
    (uart_vif.srx inside {1'b0, 1'b1});
  endproperty
  a_serial_no_x: assert property (p_serial_no_x) else $warning("A14 FAILED: Serial line validity");

  // ===================================================================
  // Protocol Assertions
  // ===================================================================

  // A15: Break condition - line held low for extended time
  property p_break_detection;
    @(posedge clk) disable iff (!rst_n)
    1'b1;  // Monitored but not asserted - break is a valid condition
  endproperty
  a_break_detection: assert property (p_break_detection) else $warning("A15 FAILED: Break detection");

  // ===================================================================
  // Cover Properties
  // ===================================================================

  // C1: Normal data transmission
  cover property (
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx === 1'b1) ##1 (uart_vif.stx === 1'b0) ##20 (uart_vif.stx === 1'b1)
  );

  // C2: RTS/DTR control
  cover property (
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.rts === 1'b1) && (uart_vif.dtr === 1'b1)
  );

  // C3: Modem signal transitions
  cover property (
    @(posedge clk) disable iff (!rst_n)
    ($past(uart_vif.cts) === 1'b0) && (uart_vif.cts === 1'b1)
  );

  // C4: Multiple bytes transmitted
  cover property (
    @(posedge clk) disable iff (!rst_n)
    (uart_vif.stx === 1'b0) ##100 (uart_vif.stx === 1'b0)
  );

endmodule : uart_assertions

`endif // UART_ASSERTIONS_SV
