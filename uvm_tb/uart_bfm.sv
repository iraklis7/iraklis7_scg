//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Bus Functional Model (BFM)                        ////
////                                                              ////
////  Implements low-level UART protocol operations              ////
////  for serial transmission and reception                      ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_BFM_SV
`define UART_BFM_SV

class uart_bfm extends uvm_component;
  virtual uart_if.driver_mp vif;
  
  bit clk_period_ns = 10;           // Default 10ns (100MHz)
  bit [15:0] divisor_latch = 16'h0001;  // Baud rate divisor
  
  `uvm_component_utils(uart_bfm)

  function new(string name = "uart_bfm", uvm_component parent);
    super.new(name, parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual uart_if.driver_mp)::get(this, "", "vif", vif))
      `uvm_fatal("UART_DRIVER", "Virtual interface not found")    
  endfunction : build_phase


  ///////////////////////////////////////////////////////////////////
  // Transmit a serial bit
  ///////////////////////////////////////////////////////////////////
  task transmit_bit(bit bit_value);
    @(posedge vif.clk);
    vif.stx = bit_value;
  endtask : transmit_bit

  ///////////////////////////////////////////////////////////////////
  // Receive a serial bit
  ///////////////////////////////////////////////////////////////////
  task receive_bit(output bit received_bit);
    @(posedge vif.clk);
    received_bit = vif.srx;
  endtask : receive_bit

  ///////////////////////////////////////////////////////////////////
  // Transmit a complete UART character
  ///////////////////////////////////////////////////////////////////
  task transmit_char(uart_seq_item item);
    int i;
    bit parity_bit;
    bit [3:0] data_bits;
    bit [7:0] tx_data;
    int total_bits;

    data_bits = item.get_data_bits();
    tx_data = item.data & ((1 << data_bits) - 1);
    parity_bit = item.get_parity_bit();
    total_bits = 1; // Start bit

    if (item.break_flag) begin
      `uvm_info(get_type_name(), "Transmitting BREAK condition", UVM_HIGH);
      repeat(16) @(posedge vif.clk);
      vif.stx <= 1'b0;  // Hold line low
      repeat(120) @(posedge vif.clk);  // Hold for 12+ bit times
      vif.stx <= 1'b1;
      return;
    end

    // Add delay if requested
    `uvm_info(get_type_name(), $sformatf("Transmitting delay cyles: %0d", item.delay_amount), UVM_HIGH);
    if (item.delay_before_tx) begin
      repeat(item.delay_amount) @(posedge vif.clk);
    end

    // Start bit
    `uvm_info(get_type_name(), $sformatf("Transmitting start bit"), UVM_HIGH);
    vif.stx <= 1'b0;
    repeat(16) @(posedge vif.clk);  // 16x oversample for one bit time

    // Data bits
    `uvm_info(get_type_name(), $sformatf("Transmitting data bits: %0d", data_bits), UVM_HIGH);
    for (i = 0; i < data_bits; i++) begin
      vif.stx <= tx_data[i];
      repeat(16) @(posedge vif.clk);
      total_bits++;
    end

    // Parity bit (if enabled)
    `uvm_info(get_type_name(), $sformatf("Transmitting parity bit: %0b", parity_bit), UVM_HIGH);
    if (item.parity_enable) begin
      if (item.error_inject) begin
        vif.stx <= ~parity_bit;
        `uvm_info(get_type_name(), $sformatf("Transmitting parity bit with ERROR: %0b", ~parity_bit), UVM_HIGH);
      end else begin
        vif.stx <= parity_bit;
      end
      repeat(16) @(posedge vif.clk);
      total_bits++;
    end

    // Stop bits
    `uvm_info(get_type_name(), $sformatf("Transmitting stop bits"), UVM_HIGH);
    vif.stx <= 1'b1;
    repeat(16) @(posedge vif.clk);
    if (item.two_stop_bits) begin
      repeat(16) @(posedge vif.clk);
    end

    // Add delay if requested
    `uvm_info(get_type_name(), $sformatf("Transmitting delay after TX: %0d cycles", item.delay_amount), UVM_HIGH);
    if (item.delay_after_tx) begin
      repeat(item.delay_amount) @(posedge vif.clk);
    end

    `uvm_info(get_type_name(), 
      $sformatf("Transmitted character: 0x%02X, word_length=%0d, parity_en=%0b, 2_stop_bits=%0b",
        item.data, data_bits, item.parity_enable, item.two_stop_bits), UVM_HIGH);

  endtask : transmit_char

  ///////////////////////////////////////////////////////////////////
  // Receive a complete UART character
  ///////////////////////////////////////////////////////////////////
  task receive_char(uart_seq_item item, output uart_seq_item rx_item);
    int i;
    bit start_bit;
    bit [7:0] rx_data = 8'h00;
    bit parity_bit;
    bit received_parity;
    bit stop_bit;
    bit [3:0] data_bits;
    int bit_count;

    rx_item = uart_seq_item::type_id::create("rx_item");

    if (item != null) begin
      rx_item.word_length = item.word_length;
      rx_item.parity_enable = item.parity_enable;
      rx_item.even_parity = item.even_parity;
      rx_item.two_stop_bits = item.two_stop_bits;
      data_bits = item.get_data_bits();
    end else begin
      data_bits = 8;
    end

    // Wait for start bit (falling edge on srx)
    wait (vif.srx == 1'b0);
    repeat(8) @(posedge vif.clk);  // Sample in middle of start bit

    // Receive data bits
    for (i = 0; i < data_bits; i++) begin
      repeat(16) @(posedge vif.clk);
      rx_data[i] = vif.srx;
    end
    rx_item.data = rx_data;

    // Receive parity bit if enabled
    if (item != null && item.parity_enable) begin
      repeat(16) @(posedge vif.clk);
      received_parity = vif.srx;
      parity_bit = item.get_parity_bit();
      if (received_parity != parity_bit) begin
        rx_item.error_inject = 1'b1;
        `uvm_warning(get_type_name(), "Parity error detected")
      end
    end

    // Receive stop bit
    repeat(16) @(posedge vif.clk);
    stop_bit = vif.srx;

    if (!stop_bit) begin
      rx_item.framing_error = 1'b1;
      `uvm_warning(get_type_name(), "Framing error detected (stop bit not high)")
    end

    if (item != null && item.two_stop_bits) begin
      repeat(16) @(posedge vif.clk);
    end

    `uvm_info(get_type_name(), 
      $sformatf("Received character: 0x%02X", rx_item.data), UVM_HIGH);

  endtask : receive_char

  ///////////////////////////////////////////////////////////////////
  // Set modem control signals
  ///////////////////////////////////////////////////////////////////
  task set_modem_controls(bit rts_val, bit dtr_val);
    vif.rts <= rts_val;
    vif.dtr <= dtr_val;
    `uvm_info(get_type_name(), $sformatf("Set RTS=%0b, DTR=%0b", rts_val, dtr_val), UVM_HIGH);
  endtask : set_modem_controls

  ///////////////////////////////////////////////////////////////////
  // Get modem status signals
  ///////////////////////////////////////////////////////////////////
  task get_modem_status(output bit cts_val, output bit dsr_val, 
                        output bit ri_val, output bit dcd_val);
    cts_val = vif.cts;
    dsr_val = vif.dsr;
    ri_val = vif.ri;
    dcd_val = vif.dcd;
  endtask : get_modem_status

  ///////////////////////////////////////////////////////////////////
  // Wait for idle line (srx and stx both high for specified cycles)
  ///////////////////////////////////////////////////////////////////
  task wait_for_idle(int cycles = 100);
    repeat(cycles) begin
      if (vif.srx && vif.stx) begin
        @(posedge vif.clk);
      end else begin
        repeat(cycles) @(posedge vif.clk);
        return;
      end
    end
  endtask : wait_for_idle

endclass : uart_bfm

`endif // UART_BFM_SV
