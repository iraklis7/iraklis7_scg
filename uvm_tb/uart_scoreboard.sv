//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART UVM Scoreboard                                        ////
////                                                              ////
////  Compares expected vs actual transactions                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  // Analysis ports for monitor connections (direct connections not used)
  // Instead, monitor will write to these ports and we handle them internally
  uvm_analysis_port #(uart_seq_item) tx_imp;
  uvm_analysis_port #(uart_seq_item) rx_imp;

  // Queues for transaction matching
  uart_seq_item tx_queue[$];
  uart_seq_item rx_queue[$];

  // Statistics
  int unsigned total_tx_checked = 0;
  int unsigned total_rx_checked = 0;
  int unsigned tx_match_count = 0;
  int unsigned rx_match_count = 0;
  int unsigned tx_mismatch_count = 0;
  int unsigned rx_mismatch_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    tx_imp = new("tx_imp", this);
    rx_imp = new("rx_imp", this);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "UART Scoreboard instantiated", UVM_LOW);
  endfunction : build_phase

  ///////////////////////////////////////////////////////////////////
  // TX write - captures TX transactions
  ///////////////////////////////////////////////////////////////////
  function void write_tx(uart_seq_item item);
    `uvm_info(get_type_name(), 
      $sformatf("TX item received: 0x%02X", item.data), UVM_HIGH);
    tx_queue.push_back(item);
  endfunction : write_tx

  ///////////////////////////////////////////////////////////////////
  // RX write - captures RX transactions
  ///////////////////////////////////////////////////////////////////
  function void write_rx(uart_seq_item item);
    `uvm_info(get_type_name(), 
      $sformatf("RX item received: 0x%02X", item.data), UVM_HIGH);
    rx_queue.push_back(item);
    check_transactions();
  endfunction : write_rx

  ///////////////////////////////////////////////////////////////////
  // Compare TX and RX transactions
  ///////////////////////////////////////////////////////////////////
  function void check_transactions();
    uart_seq_item tx_item, rx_item;

    if (tx_queue.size() > 0 && rx_queue.size() > 0) begin
      tx_item = tx_queue.pop_front();
      rx_item = rx_queue.pop_front();

      total_tx_checked++;
      total_rx_checked++;

      if (tx_item.data === rx_item.data) begin
        tx_match_count++;
        rx_match_count++;
        `uvm_info(get_type_name(), 
          $sformatf("MATCH: TX 0x%02X == RX 0x%02X", tx_item.data, rx_item.data), UVM_HIGH);
      end else begin
        tx_mismatch_count++;
        rx_mismatch_count++;
        `uvm_warning(get_type_name(), 
          $sformatf("MISMATCH: TX 0x%02X != RX 0x%02X", tx_item.data, rx_item.data))
      end

      // Check for error conditions
      if (tx_item.error_inject && !rx_item.error_inject) begin
        `uvm_warning(get_type_name(), "Parity error was injected in TX but not detected in RX")
      end

      if (tx_item.framing_error && !rx_item.framing_error) begin
        `uvm_warning(get_type_name(), "Framing error was set in TX but not detected in RX")
      end
    end
  endfunction : check_transactions

  function void report_phase(uvm_report_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "=== UART Scoreboard Report ===", UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("TX Transactions Checked: %0d", total_tx_checked), UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("RX Transactions Checked: %0d", total_rx_checked), UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("TX Matches: %0d", tx_match_count), UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("RX Matches: %0d", rx_match_count), UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("TX Mismatches: %0d", tx_mismatch_count), UVM_LOW);
    `uvm_info(get_type_name(), 
      $sformatf("RX Mismatches: %0d", rx_mismatch_count), UVM_LOW);

    if (tx_mismatch_count > 0 || rx_mismatch_count > 0) begin
      `uvm_error(get_type_name(), "Mismatches detected in scoreboard!")
    end
  endfunction : report_phase

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
