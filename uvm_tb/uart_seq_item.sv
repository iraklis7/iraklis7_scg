//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Sequence Item                                     ////
////                                                              ////
////  Represents a UART transaction including data, parity,      ////
////  stop bits, and modem control signals                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

class uart_seq_item extends uvm_sequence_item;
  `uvm_object_utils(uart_seq_item)

  // Data fields
  rand bit [7:0] data;              // 8-bit data payload
  rand bit [1:0] word_length;       // 0=5 bits, 1=6 bits, 2=7 bits, 3=8 bits
  rand bit       parity_enable;     // Enable parity
  rand bit       even_parity;       // 1=even, 0=odd
  rand bit       two_stop_bits;     // 1=2 stop bits, 0=1 stop bit
  rand bit       break_flag;        // Break condition
  rand bit       error_inject;      // Inject parity error
  rand bit       framing_error;     // Inject framing error

  // Modem signals
  rand bit       rts;               // Request to Send
  rand bit       dtr;               // Data Terminal Ready
  rand bit       cts;               // Clear to Send
  rand bit       dsr;               // Data Set Ready
  rand bit       ri;                // Ring Indicator
  rand bit       dcd;               // Data Carrier Detect
  
  // Transaction timing
  rand int       wait_cycles;       // Cycles to wait after transmission
  
  // Delay controls
  rand bit       delay_before_tx;   // Add delay before transmit
  rand bit       delay_after_tx;    // Add delay after transmit
  int            delay_amount;      // Amount of delay in cycles

  // `uvm_object_utils_begin(uart_seq_item)
    // `uvm_field_int(data, UVM_DEFAULT)
    // `uvm_field_int(word_length, UVM_DEFAULT)
    // `uvm_field_int(parity_enable, UVM_DEFAULT)
    // `uvm_field_int(even_parity, UVM_DEFAULT)
    // `uvm_field_int(two_stop_bits, UVM_DEFAULT)
    // `uvm_field_int(break_flag, UVM_DEFAULT)
    // `uvm_field_int(error_inject, UVM_DEFAULT)
    // `uvm_field_int(framing_error, UVM_DEFAULT)
    // `uvm_field_int(rts, UVM_DEFAULT)
    // `uvm_field_int(dtr, UVM_DEFAULT)
    // `uvm_field_int(cts, UVM_DEFAULT)
    // `uvm_field_int(dsr, UVM_DEFAULT)
    // `uvm_field_int(ri, UVM_DEFAULT)
    // `uvm_field_int(dcd, UVM_DEFAULT)
    // `uvm_field_int(wait_cycles, UVM_DEFAULT)
  // `uvm_object_utils_end

  // Constraints
  constraint word_length_c { word_length inside {[0:3]}; }
  constraint wait_cycles_c { wait_cycles inside {[1:100]}; }
  constraint delay_amount_c { delay_amount inside {[1:20]}; }

  function new(string name = "uart_seq_item");
    super.new(name);
    this.data = 8'h00;
    this.word_length = 2'h3;        // Default to 8 bits
    this.parity_enable = 1'b0;
    this.even_parity = 1'b0;
    this.two_stop_bits = 1'b0;      // Default to 1 stop bit
    this.break_flag = 1'b0;
    this.error_inject = 1'b0;
    this.framing_error = 1'b0;
    this.wait_cycles = 10;
    this.delay_amount = 5;
  endfunction : new

  function bit [3:0] get_data_bits();
    // Returns actual number of data bits based on word_length
    case (word_length)
      2'b00: return 4'd5;   // 5
      2'b01: return 4'd6;   // 6
      2'b10: return 4'd7;   // 7
      2'b11: return 4'd8;   // 8
    endcase
  endfunction : get_data_bits

  function bit get_parity_bit();
    bit parity_calc;
    int ones;
    int i;
    
    ones = 0;
    for (i = 0; i < get_data_bits(); i++) begin
      if (data[i]) ones++;
    end
    
    if (even_parity) begin
      return bit'(ones % 2);  // Even parity
    end else begin
      return bit'(~(ones % 2));  // Odd parity
    end
  endfunction : get_parity_bit

endclass : uart_seq_item

`endif // UART_SEQ_ITEM_SV
