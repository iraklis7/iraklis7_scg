//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Tests                                             ////
////                                                              ////
////  Collection of test cases for UART verification             ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_TESTS_SV
`define UART_TESTS_SV

// =====================================================================
// Base Test Class
// =====================================================================
class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uart_env env;
  uart_base_seq  seq;

  function new(string name = "uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("BASE TEST", "Build phase", UVM_MEDIUM);

    env = uart_env::type_id::create("env", this);
    seq = uart_base_seq::type_id::create("seq");
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Objection raised", UVM_MEDIUM);
    seq.start(env.agent.sequencer);
    `uvm_info("TEST", "About to drop objection", UVM_MEDIUM);
    phase.drop_objection(this);
    `uvm_info("TEST", "Objection dropped", UVM_MEDIUM);
  endtask : run_phase

endclass : uart_base_test

// =====================================================================
// Smoke Test - Basic functionality
// =====================================================================
class uart_smoke_test extends uart_base_test;
  `uvm_component_utils(uart_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("SMOKE_SEQ", "Seq new", UVM_MEDIUM);
  endfunction : new

  //function void build_phase(uvm_phase phase);
  //  `uvm_info("SMOKE_SEQ", "Seq build ENTRY", UVM_MEDIUM);
  //  super.build_phase(phase);
  //  `uvm_info("SMOKE_SEQ", "Seq build EXIT", UVM_MEDIUM);
  //endfunction : build_phase

  task run_phase(uvm_phase phase);
    uart_simple_data_seq smoke_seq;

    phase.raise_objection(this);
    `uvm_info("SMOKE_SEQ", "OBJ raise", UVM_MEDIUM);
    
    smoke_seq = uart_simple_data_seq::type_id::create("smoke_seq");
    smoke_seq.num_items = 5;
    smoke_seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_smoke_test

// =====================================================================
// Data Pattern Test
// =====================================================================
class uart_data_pattern_test extends uart_base_test;

  `uvm_component_utils(uart_data_pattern_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_all_patterns_seq seq;

    phase.raise_objection(this);

    seq = uart_all_patterns_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #200us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_data_pattern_test

// =====================================================================
// Parity Test
// =====================================================================
class uart_parity_test extends uart_base_test;

  `uvm_component_utils(uart_parity_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_parity_test_seq seq;

    phase.raise_objection(this);

    seq = uart_parity_test_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #300us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_parity_test

// =====================================================================
// Word Length Test
// =====================================================================
class uart_word_length_test extends uart_base_test;

  `uvm_component_utils(uart_word_length_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_word_length_test_seq seq;

    phase.raise_objection(this);

    seq = uart_word_length_test_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #400us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_word_length_test

// =====================================================================
// Stop Bit Test
// =====================================================================
class uart_stop_bit_test extends uart_base_test;

  `uvm_component_utils(uart_stop_bit_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_stop_bit_test_seq seq;

    phase.raise_objection(this);

    seq = uart_stop_bit_test_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #300us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_stop_bit_test

// =====================================================================
// Modem Control Test
// =====================================================================
class uart_modem_control_test extends uart_base_test;

  `uvm_component_utils(uart_modem_control_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_modem_control_seq seq;

    phase.raise_objection(this);

    seq = uart_modem_control_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #300us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_modem_control_test

// =====================================================================
// Break Condition Test
// =====================================================================
class uart_break_test extends uart_base_test;

  `uvm_component_utils(uart_break_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_break_test_seq seq;

    phase.raise_objection(this);

    seq = uart_break_test_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #500us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_break_test

// =====================================================================
// Comprehensive Test - All sequences
// =====================================================================
class uart_comprehensive_test extends uart_base_test;

  `uvm_component_utils(uart_comprehensive_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    uart_simple_data_seq simple_seq;
    uart_all_patterns_seq pattern_seq;
    uart_parity_test_seq parity_seq;
    uart_word_length_test_seq wl_seq;
    uart_stop_bit_test_seq sb_seq;
    uart_modem_control_seq modem_seq;

    phase.raise_objection(this);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Simple Data Sequence", UVM_LOW);
    simple_seq = uart_simple_data_seq::type_id::create("simple_seq");
    simple_seq.num_items = 5;
    simple_seq.start(env.agent.sequencer);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Pattern Sequence", UVM_LOW);
    pattern_seq = uart_all_patterns_seq::type_id::create("pattern_seq");
    pattern_seq.start(env.agent.sequencer);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Parity Test Sequence", UVM_LOW);
    parity_seq = uart_parity_test_seq::type_id::create("parity_seq");
    parity_seq.start(env.agent.sequencer);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Word Length Test Sequence", UVM_LOW);
    wl_seq = uart_word_length_test_seq::type_id::create("wl_seq");
    wl_seq.start(env.agent.sequencer);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Stop Bit Test Sequence", UVM_LOW);
    sb_seq = uart_stop_bit_test_seq::type_id::create("sb_seq");
    sb_seq.start(env.agent.sequencer);

    `uvm_info("UART_COMPREHENSIVE_TEST", "Starting Modem Control Sequence", UVM_LOW);
    modem_seq = uart_modem_control_seq::type_id::create("modem_seq");
    modem_seq.start(env.agent.sequencer);

    #500us;
    phase.drop_objection(this);
  endtask : run_phase

endclass : uart_comprehensive_test

`endif // UART_TESTS_SV
