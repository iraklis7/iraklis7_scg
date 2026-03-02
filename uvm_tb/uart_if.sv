//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Interface Definition                              ////
////                                                              ////
////  Defines the UART interface for UVM testbench               ////
////  Includes serial signals and modem control signals          ////
////                                                              ////
////  Compatible with UART 16550 specification                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

interface uart_if (input bit clk, input bit rst_n);

  // Serial signals
  logic stx;          // Serial Transmit output
  logic srx;          // Serial Receive input

  // Modem control signals
  logic rts;          // Request to Send output
  logic cts;          // Clear to Send input
  logic dtr;          // Data Terminal Ready output
  logic dsr;          // Data Set Ready input
  logic ri;           // Ring Indicator input
  logic dcd;          // Data Carrier Detect input

  // Modport for monitoring (passive)
  modport monitor_mp (
    input clk, rst_n, stx, srx, rts, cts, dtr, dsr, ri, dcd
  );

  // Modport for driving transmit side (active)
  modport transmitter_mp (
    input clk, rst_n,
    output stx, rts, dtr,
    input cts, dsr, ri, dcd
  );

  // Modport for driving receive side (active)
  modport receiver_mp (
    input clk, rst_n,
    output srx,
    input stx, rts, dtr, cts, dsr, ri, dcd
  );


  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    input cts, dsr, ri, dcd;
    output stx, rts, dtr, srx;
  endclocking

  modport driver_mp (clocking driver_cb, input clk, rst_n);
  // Modport for driver (active)
//  modport driver_mp (
//    input clk, rst_n,
//    output stx, rts, dtr, srx, test,
//    input cts, dsr, ri, dcd
//  );

endinterface : uart_if
