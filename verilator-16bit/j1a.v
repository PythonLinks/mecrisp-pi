
`default_nettype none

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */

`include "../common-verilog/j1-universal-16kb.v"
`include "../common-verilog/spi-out.v"
`include "../common-verilog/spi-in.v"

module j1a(
           input wire clk,
           input wire resetq,

           output wire uart0_wr,
           output wire uart0_rd,
           output wire [7:0] uart_w,

           input wire uart0_busy,
           input wire uart0_valid,
           input wire [7:0] uart0_data

);

  // ######   Clock   #########################################


  // ######   Reset logic   ###################################


  // ######   Bus    ##########################################

  wire io_rd, io_wr;
  wire [15:0] io_addr;
  wire [15:0] io_dout;
  wire [15:0] io_din;

  reg interrupt = 0;

  // ######   PROCESSOR   #####################################

  j1 _j1(
    .clk(clk),
    .resetq(resetq),

    .io_rd(io_rd),
    .io_wr(io_wr),
    .io_dout(io_dout),
    .io_din(io_din),
    .io_addr(io_addr),

    .interrupt_request(interrupt)
  );

  // ######   TICKS   #########################################

  reg [15:0] ticks;

  wire [16:0] ticks_plus_1 = ticks + 1;

  always @(posedge clk)
    if (io_wr & io_addr[14])
      ticks <= io_dout;
    else
      ticks <= ticks_plus_1[15:0];

  always @(posedge clk) // Generate interrupt on ticks overflow
    interrupt <= ticks_plus_1[16];

  // ######   PORTA   #########################################

  reg  [15:0] porta_dir;   // 1:output, 0:input
  reg  [15:0] porta_out;
  wire [15:0] porta_in;

  // ######   PORTB   #########################################

  reg  [15:0] portb_dir;   // 1:output, 0:input
  reg  [15:0] portb_out;
  wire [15:0] portb_in;

  // ######   PORTC   #########################################

  reg  [15:0] portc_dir;   // 1:output, 0:input
  reg  [15:0] portc_out;
  wire [15:0] portc_in;

  assign porta_in = 0;
  assign portb_in = 0;
  assign portc_in = 0;

  // ######   UART   ##########################################

  assign uart0_wr = io_wr & io_addr[12];
  assign uart0_rd = io_rd & io_addr[12];

  assign uart_w = io_dout[7:0];

  // ######   IO PORTS   ######################################

  /*        bit READ            WRITE

      0001  0   PMOD in
      0002  1   PMOD out        PMOD out
      0004  2   PMOD dir        PMOD dir
      0008  3

      0010  4   header 1 in
      0020  5   header 1 out    header 1 out
      0040  6   header 1 dir    header 1 dir
      0080  7

      0100  8   header 2 in
      0200  9   header 2 out    header 2 out
      0400  10  header 2 dir    header 2 dir
      0800  11

      1000  12  UART RX         UART TX
      2000  13  misc.in
      4000  14  ticks           clear ticks
      8000  15
  */

  assign io_din =

    (io_addr[ 0] ?         porta_in                                                 : 16'd0) |
    (io_addr[ 1] ?         porta_out                                                : 16'd0) |
    (io_addr[ 2] ?         porta_dir                                                : 16'd0) |

    (io_addr[ 4] ?         portb_in                                                 : 16'd0) |
    (io_addr[ 5] ?         portb_out                                                : 16'd0) |
    (io_addr[ 6] ?         portb_dir                                                : 16'd0) |

    (io_addr[ 8] ?         portc_in                                                 : 16'd0) |
    (io_addr[ 9] ?         portc_out                                                : 16'd0) |
    (io_addr[10] ?         portc_dir                                                : 16'd0) |

    (io_addr[12] ? { 8'd0, uart0_data}                                              : 16'd0) |
    (io_addr[13] ? {14'd0, uart0_valid, !uart0_busy}                                : 16'd0) |
    (io_addr[14] ?         ticks                                                    : 16'd0) ;

  always @(posedge clk) begin

    if (io_wr & io_addr[1])  porta_out <= io_dout;
    if (io_wr & io_addr[2])  porta_dir <= io_dout;

    if (io_wr & io_addr[5])  portb_out <= io_dout;
    if (io_wr & io_addr[6])  portb_dir <= io_dout;

    if (io_wr & io_addr[9])  portc_out <= io_dout;
    if (io_wr & io_addr[10]) portc_dir <= io_dout;

  end

endmodule
