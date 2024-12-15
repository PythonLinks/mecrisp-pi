
`default_nettype none

`define cfg_divider  104  // 12 MHz / 115200 = 104.17
`include "../common-verilog/uart.v"
`include "./verilog/j1-universal-16kb.v"
`include "../common-verilog/spi-out.v"
//`define UPDUINO
`ifdef UPDUINO
`include "./verilog/oscillator.v"
`endif

`include "../common-verilog/spi-in.v"


module top(
           `ifndef UPDUINO
           input  oscillator,
           `endif
           output TXD,        // UART TX
           input  RXD,        // UART RX

           input reset_button
);



// ######   Clock   #########################################
`ifdef UPDUINO
   wire		 clk;
  oscilator oscilator (.clk(clk));
`else
  wire clk = oscillator;
`endif
   
  // ######   Reset logic   ###################################

  reg [3:0] reset_cnt = 0;
  wire resetq = &reset_cnt;

  always @(posedge clk) begin
    if (reset_button) reset_cnt <= reset_cnt + !resetq;
    else              reset_cnt <= 0;
  end

  // ######   Bus    ##########################################

  wire io_rd, io_wr;
  wire [15:0] io_addr;
  wire [15:0] io_dout;
  wire [15:0] io_din;

  wire interrupt;


  // ######   Terminal   ######################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr & io_addr[12];
  wire uart0_rd = io_rd & io_addr[12];

  buart _uart0 (
     .clk(clk),
     .resetq(resetq),
     .rx(RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(io_dout[7:0]),
     .rx_data(uart0_data));

`include "../common-verilog/shared.v"
   
endmodule // top
