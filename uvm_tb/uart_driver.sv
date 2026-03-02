//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Driver                                            ////
////                                                              ////
////  Drives UART transactions using the BFM                    ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_seq_item);
  virtual uart_if.driver_mp vif;
  uart_bfm bfm;

  // Configuration
  bit enable_rts = 1'b1;
  bit enable_dtr = 1'b1;
  int default_wait_cycles = 10;

  // Statistics
  int unsigned num_tx = 0;
  int unsigned num_rx = 0;

  `uvm_component_utils(uart_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //if (!uvm_config_db#(virtual sig_if.DRIVER)::get(this, "", "vif", vif))

    bfm = uart_bfm::type_id::create("bfm", this);
    
    if (!uvm_config_db #(virtual uart_if.driver_mp)::get(this, "", "vif", vif))
      `uvm_fatal("UART_DRIVER", "Virtual interface not found")    
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // `bfm.vif = vif;
  endfunction : connect_phase

  virtual task run_phase(uvm_phase phase);
    uart_seq_item item;
    bit cts, dsr, ri, dcd;

    // Initialize interface
    vif.driver_cb.stx <= 1'b1;
    // XXX
    vif.driver_cb.srx <= 1'b1;
    vif.driver_cb.rts <= enable_rts;
    vif.driver_cb.dtr <= enable_dtr;

    forever begin
      seq_item_port.get_next_item(item);

      // Check if we should drive this item
      if (item != null) begin
        case (item.get_type_name())
          // Default: assume transmission
          default: begin
            drive_transaction(item);
          end
        endcase
      end
      // Wait for specified cycles
      repeat(item.wait_cycles) @(posedge vif.clk);
      
      seq_item_port.item_done(item);
    end
  endtask : run_phase

  task drive_transaction(uart_seq_item item);
    bit cts, dsr, ri, dcd;
    
    // Optionally update modem control signals
    if (item.rts || item.dtr) begin
      bfm.set_modem_controls(item.rts, item.dtr);
    end

    // Check modem status
    bfm.get_modem_status(cts, dsr, ri, dcd);
    
    // If CTS is high or loopback is enabled, transmit the character
    if (cts || 1'b1) begin  // Drive even if CTS low for testing purposes
      bfm.transmit_char(item);
      num_tx++;
      `uvm_info(get_type_name(), $sformatf("Transmitted item #%0d: data=0x%02X", num_tx, item.data), UVM_LOW);
    end else begin
      `uvm_warning(get_type_name(), "CTS signal low, skipping transmission")
    end
  endtask : drive_transaction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("UART Driver Report: TX Count = %0d, RX Count = %0d", num_tx, num_rx), UVM_LOW);
  endfunction : report_phase

endclass : uart_driver

`endif // UART_DRIVER_SV
