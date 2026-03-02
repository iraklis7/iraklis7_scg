//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Testbench Top Module                              ////
////                                                              ////
////  Top-level module that instantiates DUT and testbench       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_TB_TOP_SV
`define UART_TB_TOP_SV

// `timescale 1ns/1ps

module uart_tb_top;
  import uvm_pkg::*;
  import uart_pkg::*;

  // Clock and reset generation
  bit clk = 1;
  bit rst_n = 1;

  // Clock generation: 100 MHz
  initial begin
    $dumpfile("uart_test.vcd");
    $dumpvars(0);
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    rst_n = 1;
  end

  // UART Interface instantiation
  uart_if uart_if_inst (
    .clk(clk),
    .rst_n(rst_n)
  );

  // Optional: Add waveform dumping
  //initial begin
    //if ($test$plusargs("dump_waveforms")) begin
      //$dumpfile("uart_tb.vcd");
      //$dumpvars(0, uart_tb_top);
    //end
  //end

  // Optional: Timeout to prevent infinite loops
  initial begin
    #10ms;
    $display("Simulation timeout reached");
    $finish();
  end

  // Pass interface to test via config_db
  initial begin
    uvm_config_db#(virtual uart_if.driver_mp)::set(uvm_root::get(), "*", "vif", uart_if_inst.driver_mp);
    uvm_config_db#(virtual uart_if.monitor_mp)::set(uvm_root::get(), "*", "vif", uart_if_inst.monitor_mp);
  end

  // Run UVM test
  initial begin
    run_test();
  end

endmodule : uart_tb_top

`endif // UART_TB_TOP_SV
