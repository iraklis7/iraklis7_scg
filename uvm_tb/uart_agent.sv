//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Agent                                             ////
////                                                              ////
////  Top-level agent containing sequencer, driver, and monitor  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;

  `uvm_component_utils(uart_agent)

  uart_sequencer sequencer;
  uart_driver driver;
  uart_monitor monitor;
  //uart_coverage coverage;

  //virtual uart_if uart_vif;

  bit is_active = UVM_ACTIVE;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "Building UART Agent", UVM_LOW);

    // Create active components only if agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_type_name(), "UART Agent is ACTIVE", UVM_LOW);
      sequencer = uart_sequencer::type_id::create("sequencer", this);
      driver = uart_driver::type_id::create("driver", this);
    end

    // Create monitor (always active)
    monitor = uart_monitor::type_id::create("monitor", this);
    
    // XXX: Create coverage collector
    //coverage = uart_coverage::type_id::create("coverage", this);

    //if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", uart_vif)) begin
      //`uvm_fatal("UART_AGENT", "Virtual interface not found in config_db")
    //end

    // Store interface in config_db for children
    //uvm_config_db #(virtual uart_if)::set(this, "*", "uart_vif", uart_vif);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Starting Connect phase", UVM_LOW);

    // Connect driver to sequencer if active
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end

    // Connect monitor analysis port to coverage
    // monitor.tx_analysis_port.connect(coverage.analysis_export);
    // monitor.rx_analysis_port.connect(coverage.analysis_export);
  endfunction : connect_phase

endclass : uart_agent

`endif // UART_AGENT_SV
