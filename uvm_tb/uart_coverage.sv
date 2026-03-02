//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Coverage Collector                                ////
////                                                              ////
////  Collects functional coverage for UART verification         ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber #(uart_seq_item);

  `uvm_component_utils(uart_coverage)

  // Coverage groups
  covergroup uart_data_cg;
    option.per_instance = 1;
    
    // Data pattern coverage
    data_cp: coverpoint uart_item.data {
      bins all_zeros = {8'h00};
      bins all_ones = {8'hFF};
      bins low_byte = {[8'h00:8'h0F]};
      bins mid_byte = {[8'h40:8'hBF]};
      bins high_byte = {[8'hF0:8'hFE]};
      illegal_bins never_ones = {8'h00};
    }
    
    // Word length coverage
    word_length_cp: coverpoint uart_item.word_length {
      bins five_bits = {2'b00};
      bins six_bits = {2'b01};
      bins seven_bits = {2'b10};
      bins eight_bits = {2'b11};
    }
    
    // Parity coverage
    parity_cp: coverpoint {uart_item.parity_enable, uart_item.even_parity} {
      bins no_parity = {2'b00};
      bins even_parity = {2'b10};
      bins odd_parity = {2'b11};
    }
    
    // Stop bit coverage
    stop_bit_cp: coverpoint uart_item.two_stop_bits {
      bins one_stop = {1'b0};
      bins two_stop = {1'b1};
    }
    
    // Error injection coverage
    error_cp: coverpoint uart_item.error_inject {
      bins no_error = {1'b0};
      bins with_error = {1'b1};
    }
    
    // Framing error coverage
    framing_error_cp: coverpoint uart_item.framing_error {
      bins no_framing_error = {1'b0};
      bins framing_error = {1'b1};
    }
    
    // Break flag coverage
    break_cp: coverpoint uart_item.break_flag {
      bins no_break = {1'b0};
      bins break_condition = {1'b1};
    }

    // Cross coverage
    word_parity_cross: cross word_length_cp, parity_cp;
    word_stop_cross: cross word_length_cp, stop_bit_cp;
    parity_error_cross: cross parity_cp, error_cp;
  endgroup : uart_data_cg

  covergroup uart_modem_cg;
    option.per_instance = 1;
    
    // Modem control signal coverage
    rts_cp: coverpoint uart_item.rts {
      bins rts_low = {1'b0};
      bins rts_high = {1'b1};
    }
    
    dtr_cp: coverpoint uart_item.dtr {
      bins dtr_low = {1'b0};
      bins dtr_high = {1'b1};
    }
    
    cts_cp: coverpoint uart_item.cts {
      bins cts_low = {1'b0};
      bins cts_high = {1'b1};
    }
    
    dsr_cp: coverpoint uart_item.dsr {
      bins dsr_low = {1'b0};
      bins dsr_high = {1'b1};
    }
    
    ri_cp: coverpoint uart_item.ri {
      bins ri_low = {1'b0};
      bins ri_high = {1'b1};
    }
    
    dcd_cp: coverpoint uart_item.dcd {
      bins dcd_low = {1'b0};
      bins dcd_high = {1'b1};
    }

    // Modem cross coverage
    handshake_cross: cross rts_cp, cts_cp;
    dtr_dsr_cross: cross dtr_cp, dsr_cp;
  endgroup : uart_modem_cg

  covergroup uart_timing_cg;
    option.per_instance = 1;
    
    // Wait cycles coverage
    wait_cycles_cp: coverpoint uart_item.wait_cycles {
      bins short_wait = {[1:10]};
      bins medium_wait = {[11:50]};
      bins long_wait = {[51:100]};
    }
    
    // Delay coverage
    delay_before_cp: coverpoint uart_item.delay_before_tx {
      bins no_delay = {1'b0};
      bins with_delay = {1'b1};
    }
    
    delay_after_cp: coverpoint uart_item.delay_after_tx {
      bins no_delay = {1'b0};
      bins with_delay = {1'b1};
    }

    delay_timing_cross: cross delay_before_cp, delay_after_cp;
  endgroup : uart_timing_cg

  // Instance variables
  uart_seq_item uart_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    uart_data_cg = new();
    uart_modem_cg = new();
    uart_timing_cg = new();
  endfunction : new

  function void write(uart_seq_item t);
    uart_item = t;
    sample_coverage();
  endfunction : write

  function void sample_coverage();
    uart_data_cg.sample();
    uart_modem_cg.sample();
    uart_timing_cg.sample();
  endfunction : sample_coverage

  function void report_phase(uvm_report_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "UART Coverage collection complete", UVM_LOW);
  endfunction : report_phase

endclass : uart_coverage

`endif // UART_COVERAGE_SV
