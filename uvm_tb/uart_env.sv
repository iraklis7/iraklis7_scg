//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Environment                                       ////
////                                                              ////
////  Top-level environment containing agent and scoreboard      ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_ENV_SV
`define UART_ENV_SV

class uart_env extends uvm_env;

  `uvm_component_utils(uart_env)

  uart_agent agent;
  //uart_scoreboard scoreboard;

  //virtual uart_if uart_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", uart_vif)) begin
    //  `uvm_fatal("UART_ENV", "Virtual interface not found in config_db")
    //end

    // Store interface in config_db for children
    //uvm_config_db #(virtual uart_if)::set(this, "*", "uart_vif", uart_vif);

    // Create agent
    `uvm_info("ENV", "Created agent", UVM_MEDIUM);
    agent = uart_agent::type_id::create("agent", this);

    // Create scoreboard
    //scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    //super.connect_phase(phase);
    
    // Note: Direct connections to scoreboard methods are not used.
    // Scoreboard receives transactions passively through the monitor's
    // analysis ports when they are written to.
    // In a full UVM environment, these would be connected via a port connection.
    //agent.monitor.tx_collected_port.connect(scoreboard.tx_imp);
    //agent.monitor.rx_collected_port.connect(scoreboard.rx_imp);

  endfunction : connect_phase

endclass : uart_env

`endif // UART_ENV_SV
