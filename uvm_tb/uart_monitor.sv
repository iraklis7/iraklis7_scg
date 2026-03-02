//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Monitor                                           ////
////                                                              ////
////  Monitors UART bus activity and collects functional coverage////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;

  //virtual uart_if vif;
  virtual uart_if.monitor_mp vif;

  uvm_analysis_port #(uart_seq_item) tx_collected_port;
  uvm_analysis_port #(uart_seq_item) rx_collected_port;
  uart_seq_item tx_item;
  uart_seq_item rx_item;

  // Statistics
  int unsigned total_bytes_tx = 0;
  int unsigned total_bytes_rx = 0;
  int unsigned error_count = 0;
  int unsigned parity_errors = 0;
  int unsigned framing_errors = 0;

  // Configuration
  bit monitor_tx = 1'b1;
  bit monitor_rx = 1'b1;

  `uvm_component_utils(uart_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);

    tx_item = null;
    rx_item = null;
    tx_collected_port = new("tx_collected_port", this);
    rx_collected_port = new("rx_collected_port", this);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual uart_if.monitor_mp)::get(this, "", "vif", vif)) 
      `uvm_fatal("UART_MONITOR", "Virtual interface not found")
  endfunction : build_phase


  virtual task run_phase(uvm_phase phase);
    // XXX: Need better handling phase.raise_objection(this);
    fork
      if (monitor_tx) monitor_tx_thread();
      if (monitor_rx) monitor_rx_thread();
      monitor_modem_signals();
    join_none
  endtask : run_phase

  ///////////////////////////////////////////////////////////////////
  // Monitor TX (stx) transactions
  ///////////////////////////////////////////////////////////////////
  task monitor_tx_thread();
    bit [7:0] rx_data;
    int data_bits;
    int i;

    forever begin
      tx_item = uart_seq_item::type_id::create("tx_item");
      
      // Wait for start bit (stx goes low)
      wait (vif.stx == 1'b0);
      `uvm_info(get_type_name(), $sformatf("Detected possible start bit"), UVM_HIGH);
      repeat(8) @(posedge vif.clk);  // Sample in middle of start bit
      `uvm_info(get_type_name(), $sformatf("Start bit confirmed"), UVM_HIGH);
      // Default to 8-bit, even parity, 1 stop bit
      data_bits = 8;
      tx_item.word_length = 2'b11;
      tx_item.parity_enable = 1'b0;
      tx_item.two_stop_bits = 1'b0;

      // Receive data bits
      `uvm_info(get_type_name(), $sformatf("Receiving data bits for TX item"), UVM_HIGH);
      rx_data = 8'h00;
      for (i = 0; i < data_bits; i++) begin
        repeat(16) @(posedge vif.clk);
        rx_data[i] = vif.stx;
      end
      tx_item.data = rx_data;

      // Receive stop bit
      `uvm_info(get_type_name(), $sformatf("Receiving stop bit"), UVM_HIGH);
      repeat(16) @(posedge vif.clk);
      if (vif.stx != 1'b1) begin
        tx_item.framing_error = 1'b1;
        framing_errors++;
        `uvm_warning(get_type_name(), "TX: Framing error detected (stop bit not high)")
      end

      total_bytes_tx++;
      tx_collected_port.write(tx_item);
      
      `uvm_info(get_type_name(), 
        $sformatf("Monitored TX: 0x%02X (byte #%0d)", tx_item.data, total_bytes_tx), UVM_HIGH);
    end
  endtask : monitor_tx_thread

  ///////////////////////////////////////////////////////////////////
  // Monitor RX (srx) transactions
  ///////////////////////////////////////////////////////////////////
  task monitor_rx_thread();
    bit [7:0] rx_data;
    int data_bits;
    int i;

    forever begin
      rx_item = uart_seq_item::type_id::create("rx_item");
      
      // Wait for start bit (srx goes low)
      wait (vif.srx == 1'b0);
      `uvm_info(get_type_name(), $sformatf("Detected possible start bit"), UVM_HIGH);
      repeat(8) @(posedge vif.clk);  // Sample in middle of start bit
      `uvm_info(get_type_name(), $sformatf("Start bit confirmed"), UVM_HIGH);

      // Default to 8-bit, even parity, 1 stop bit
      data_bits = 8;
      rx_item.word_length = 2'b11;
      rx_item.parity_enable = 1'b0;
      rx_item.two_stop_bits = 1'b0;

      // Receive data bits
      `uvm_info(get_type_name(), $sformatf("Receiving data bits for RX item"), UVM_HIGH);
      rx_data = 8'h00;
      for (i = 0; i < data_bits; i++) begin
        repeat(16) @(posedge vif.clk);
        rx_data[i] = vif.srx;
      end
      rx_item.data = rx_data;

      // Receive stop bit
      `uvm_info(get_type_name(), $sformatf("Receiving stop bit"), UVM_HIGH);
      repeat(16) @(posedge vif.clk);
      if (vif.srx != 1'b1) begin
        rx_item.framing_error = 1'b1;
        framing_errors++;
        `uvm_warning(get_type_name(), "RX: Framing error detected (stop bit not high)")
      end

      total_bytes_rx++;
      rx_collected_port.write(rx_item);
      
      `uvm_info(get_type_name(), 
        $sformatf("Monitored RX: 0x%02X (byte #%0d)", rx_item.data, total_bytes_rx), UVM_HIGH);
    end
  endtask : monitor_rx_thread

  ///////////////////////////////////////////////////////////////////
  // Monitor modem signals
  ///////////////////////////////////////////////////////////////////
  task monitor_modem_signals();
    bit prev_rts = 1'b1;
    bit prev_dtr = 1'b1;
    bit prev_cts = 1'b1;
    bit prev_dsr = 1'b1;
    bit prev_ri = 1'b0;
    bit prev_dcd = 1'b1;

    forever begin
      @(posedge vif.clk);

      // Detect changes
      if (vif.rts !== prev_rts) begin
        `uvm_info(get_type_name(), $sformatf("RTS changed to %0b", vif.rts), UVM_HIGH);
        prev_rts = vif.rts;
      end

      if (vif.dtr !== prev_dtr) begin
        `uvm_info(get_type_name(), $sformatf("DTR changed to %0b", vif.dtr), UVM_HIGH);
        prev_dtr = vif.dtr;
      end

      if (vif.cts !== prev_cts) begin
        `uvm_info(get_type_name(), $sformatf("CTS changed to %0b", vif.cts), UVM_HIGH);
        prev_cts = vif.cts;
      end

      if (vif.dsr !== prev_dsr) begin
        `uvm_info(get_type_name(), $sformatf("DSR changed to %0b", vif.dsr), UVM_HIGH);
        prev_dsr = vif.dsr;
      end

      if (vif.ri !== prev_ri) begin
        `uvm_info(get_type_name(), $sformatf("RI changed to %0b", vif.ri), UVM_HIGH);
        prev_ri = vif.ri;
      end

      if (vif.dcd !== prev_dcd) begin
        `uvm_info(get_type_name(), $sformatf("DCD changed to %0b", vif.dcd), UVM_HIGH);
        prev_dcd = vif.dcd;
      end
    end
  endtask : monitor_modem_signals

  function void report_phase(uvm_report_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), 
      $sformatf("UART Monitor Report: TX Bytes=%0d, RX Bytes=%0d, Parity Errors=%0d, Framing Errors=%0d",
        total_bytes_tx, total_bytes_rx, parity_errors, framing_errors), UVM_LOW);
  endfunction : report_phase

endclass : uart_monitor

`endif // UART_MONITOR_SV
