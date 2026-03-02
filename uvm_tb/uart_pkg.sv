//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Package                                           ////
////                                                              ////
////  Package containing all UVM testbench components            ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_PKG_SV
`define UART_PKG_SV

//`timescale 1ns/1ps

package uart_pkg;
  import uvm_pkg::*;

  // Include all components in order
  `include "uart_seq_item.sv"
  `include "uart_bfm.sv"
  `include "uart_driver.sv"
  `include "uart_monitor.sv"
  `include "uart_coverage.sv"
  `include "uart_sequencer.sv"
  `include "uart_agent.sv"
  // `include "uart_scoreboard.sv"
  `include "uart_env.sv"
  `include "uart_tests.sv"

endpackage : uart_pkg

`endif // UART_PKG_SV
