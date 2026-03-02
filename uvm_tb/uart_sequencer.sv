//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Sequencer                                         ////
////                                                              ////
////  Provides sequencing logic for UART transactions             ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_SEQUENCER_SV
`define UART_SEQUENCER_SV

class uart_sequencer extends uvm_sequencer #(uart_seq_item);
  `uvm_component_utils(uart_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("SEQUENCER", "Sequencer, new", UVM_MEDIUM);
  endfunction : new

endclass : uart_sequencer

// =====================================================================
// Base Sequence
// =====================================================================
class uart_base_seq extends uvm_sequence #(uart_seq_item);
  `uvm_object_utils(uart_base_seq)

  function new(string name = "uart_base_seq");
    super.new(name);
  endfunction : new

  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "Run phase", UVM_MEDIUM);
  endtask : run_phase

  virtual task body();
    `uvm_info(get_type_name(), "Body started", UVM_MEDIUM);
  endtask : body

endclass : uart_base_seq

// =====================================================================
// Simple Data Sequence
// =====================================================================
class uart_simple_data_seq extends uart_base_seq;
  `uvm_object_utils(uart_simple_data_seq)
  
  int num_items = 10;

  function new(string name = "uart_simple_data_seq");
    super.new(name);
  endfunction : new

  task run_phase(uvm_phase phase);
    `uvm_info("SEQ", "Sequence raising", UVM_MEDIUM);
  endtask : run_phase

  task body();
    uart_seq_item item;
    int i;

    `uvm_info(get_type_name(), $sformatf("Starting simple data sequence with %0d items", num_items), UVM_LOW);

    for (i = 0; i < num_items; i++) begin
      `uvm_info(get_type_name(), $sformatf("Iteration %0d started", i), UVM_MEDIUM);
      
      item = uart_seq_item::type_id::create("item");
      // wait_for_grant();
      `uvm_info(get_type_name(), "Simple data sequence item created", UVM_MEDIUM);
      
      start_item(item);
      `uvm_info(get_type_name(), "Simple data sequence item started", UVM_MEDIUM);
      
      void'(item.randomize());
      `uvm_info(get_type_name(), "Item randomized", UVM_MEDIUM);
      
      item.word_length = 2'b11;          // 8 bits
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b0;
      item.break_flag = 1'b0;
      item.error_inject = 1'b0;
      item.wait_cycles = 20;
      //send_request(item);
      finish_item(item);
      `uvm_info("SDATA SEQ", "Item finished", UVM_MEDIUM)
      //wait_for_item_done();
    end

    `uvm_info(get_type_name(), "Simple data sequence completed", UVM_LOW);
  endtask : body

endclass : uart_simple_data_seq

// =====================================================================
// All Data Patterns Sequence
// =====================================================================
class uart_all_patterns_seq extends uart_base_seq;

  `uvm_object_utils(uart_all_patterns_seq)

  function new(string name = "uart_all_patterns_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i;
    bit [7:0] patterns[] = {8'h00, 8'hFF, 8'hAA, 8'h55, 8'h33, 8'hCC, 8'h0F, 8'hF0};

    `uvm_info(get_type_name(), "Starting all patterns sequence", UVM_LOW);

    foreach (patterns[idx]) begin
      item = uart_seq_item::type_id::create("item");
      start_item(item);
      item.data = patterns[idx];
      item.word_length = 2'b11;
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b0;
      item.break_flag = 1'b0;
      item.error_inject = 1'b0;
      item.wait_cycles = 25;
      finish_item(item);
    end

    `uvm_info(get_type_name(), "All patterns sequence completed", UVM_LOW);
  endtask : body

endclass : uart_all_patterns_seq

// =====================================================================
// Parity Test Sequence
// =====================================================================
class uart_parity_test_seq extends uart_base_seq;

  `uvm_object_utils(uart_parity_test_seq)

  function new(string name = "uart_parity_test_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i;
    bit parity_types[] = {1'b0, 1'b1};  // odd and even

    `uvm_info(get_type_name(), "Starting parity test sequence", UVM_LOW);

    foreach (parity_types[ptype_idx]) begin
      for (i = 0; i < 10; i++) begin
        item = uart_seq_item::type_id::create("item");
        start_item(item);
        if( item.randomize() );
        item.word_length = 2'b11;
        item.parity_enable = 1'b1;
        item.even_parity = parity_types[ptype_idx];
        item.two_stop_bits = 1'b0;
        item.break_flag = 1'b0;
        item.error_inject = 1'b0;
        item.wait_cycles = 25;
        finish_item(item);
      end
    end

    `uvm_info(get_type_name(), "Parity test sequence completed", UVM_LOW);
  endtask : body

endclass : uart_parity_test_seq

// =====================================================================
// Word Length Test Sequence
// =====================================================================
class uart_word_length_test_seq extends uart_base_seq;

  `uvm_object_utils(uart_word_length_test_seq)

  function new(string name = "uart_word_length_test_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i, j;
    bit [1:0] word_lengths[] = {2'b00, 2'b01, 2'b10, 2'b11};  // 5, 6, 7, 8 bits

    `uvm_info(get_type_name(), "Starting word length test sequence", UVM_LOW);

    foreach (word_lengths[wl_idx]) begin
      for (i = 0; i < 5; i++) begin
        item = uart_seq_item::type_id::create("item");
        start_item(item);
        if( item.randomize() );
        item.word_length = word_lengths[wl_idx];
        item.parity_enable = 1'b0;
        item.two_stop_bits = 1'b0;
        item.break_flag = 1'b0;
        item.error_inject = 1'b0;
        item.wait_cycles = 25;
        finish_item(item);
      end
    end

    `uvm_info(get_type_name(), "Word length test sequence completed", UVM_LOW);
  endtask : body

endclass : uart_word_length_test_seq

// =====================================================================
// Stop Bit Test Sequence
// =====================================================================
class uart_stop_bit_test_seq extends uart_base_seq;

  `uvm_object_utils(uart_stop_bit_test_seq)

  function new(string name = "uart_stop_bit_test_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i;

    `uvm_info(get_type_name(), "Starting stop bit test sequence", UVM_LOW);

    // 1 stop bit
    for (i = 0; i < 5; i++) begin
      item = uart_seq_item::type_id::create("item");
      start_item(item);
      if( item.randomize() );
      item.word_length = 2'b11;
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b0;
      item.break_flag = 1'b0;
      item.error_inject = 1'b0;
      item.wait_cycles = 25;
      finish_item(item);
    end

    // 2 stop bits
    for (i = 0; i < 5; i++) begin
      item = uart_seq_item::type_id::create("item");
      start_item(item);
      if( item.randomize() );
      item.word_length = 2'b11;
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b1;
      item.break_flag = 1'b0;
      item.error_inject = 1'b0;
      item.wait_cycles = 25;
      finish_item(item);
    end

    `uvm_info(get_type_name(), "Stop bit test sequence completed", UVM_LOW);
  endtask : body

endclass : uart_stop_bit_test_seq

// =====================================================================
// Modem Control Sequence
// =====================================================================
class uart_modem_control_seq extends uart_base_seq;

  `uvm_object_utils(uart_modem_control_seq)

  function new(string name = "uart_modem_control_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i;

    `uvm_info(get_type_name(), "Starting modem control sequence", UVM_LOW);

    for (i = 0; i < 10; i++) begin
      item = uart_seq_item::type_id::create("item");
      start_item(item);
      if( item.randomize() );
      item.word_length = 2'b11;
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b0;
      item.break_flag = 1'b0;
      item.error_inject = 1'b0;
      item.wait_cycles = 30;
      // Let RTS, DTR randomize
      finish_item(item);
    end

    `uvm_info(get_type_name(), "Modem control sequence completed", UVM_LOW);
  endtask : body

endclass : uart_modem_control_seq

// =====================================================================
// Break Condition Sequence
// =====================================================================
class uart_break_test_seq extends uart_base_seq;

  `uvm_object_utils(uart_break_test_seq)

  function new(string name = "uart_break_test_seq");
    super.new(name);
  endfunction : new

  task body();
    uart_seq_item item;
    int i;

    `uvm_info(get_type_name(), "Starting break condition test sequence", UVM_LOW);

    for (i = 0; i < 5; i++) begin
      item = uart_seq_item::type_id::create("item");
      start_item(item);
      item.data = 8'h00;
      item.word_length = 2'b11;
      item.parity_enable = 1'b0;
      item.two_stop_bits = 1'b0;
      item.break_flag = 1'b1;
      item.error_inject = 1'b0;
      item.wait_cycles = 200;
      finish_item(item);
    end

    `uvm_info(get_type_name(), "Break condition test sequence completed", UVM_LOW);
  endtask : body

endclass : uart_break_test_seq

`endif // UART_SEQUENCER_SV
