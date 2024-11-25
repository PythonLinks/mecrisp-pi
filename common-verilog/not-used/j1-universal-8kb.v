
`default_nettype none

`include "../common-verilog/stack2.v"

module j1(
  input wire clk,
  input wire resetq,

  output wire io_rd,
  output wire io_wr,
  output wire [15:0] io_addr,
  output wire [15:0] io_dout,
  input  wire [15:0] io_din,

  input  wire interrupt_request
);

  // ######   MEMORY   ########################################

    wire mem_wr;
    wire [12:0] code_addr;
    reg  [15:0] insn_from_memory;

    reg [15:0] mem [0:4096-1]; initial $readmemh("build/iceimage.hex", mem); // 4k words of 16 bits = 8 kb.

    always @(posedge clk) begin
        insn_from_memory  <= mem[code_addr];
        if (mem_wr) mem[io_addr[12:1]] <= io_dout;
    end

  // ######   PROCESSOR   #####################################


  reg [3:0] dsp, dspN;          // Data stack pointer
  reg [15:0] st0, st0N;         // Top of data stack
  reg dstkW;                    // Data stack write

  reg [15:0] pc, pcN;           // Program Counter. pc[0] is interrupt enable bit.

  wire interrupt_enable = pc[0];
  wire interrupt = interrupt_request & interrupt_enable;

  wire [15:0] insn = interrupt ? 16'h4001 : insn_from_memory;  // Interrupt: Execute "Call 0002".
  wire [15:0] pc_plus_2 = (pc + {14'b0, ~interrupt, 1'b0}) | {interrupt, 15'b0};      // Do not increment PC for interrupts to continue later at the same location. Set MSB on interrupt entries which will be pushed to return stack !
  wire fetch = pc[13] & ~interrupt;                            // Memory fetch data on pc[13] only valid if this is no interrupt entry.

  reg rstkW;                    // Return stack write
  wire [15:0] rstkD;            // Return stack write value
  reg notreboot = 0;

  assign io_addr = st0[15:0];
  assign code_addr = pcN[13:1];

  // The D and R stacks
  wire [15:0] st1, rst0;
  reg [1:0] dspI, rspI;

  stack2 #(.DEPTH(16)) rstack(.clk(clk), .rd(rst0), .we(rstkW), .wd(rstkD), .delta(rspI));
  stack2 #(.DEPTH(16)) dstack(.clk(clk), .rd(st1),  .we(dstkW), .wd(st0),   .delta(dspI));

  wire [16:0] minus = {1'b1, ~st0} + st1 + 1;

  wire signedless = st0[15] ^ st1[15] ? st1[15] : minus[16];
  wire unsignedless = minus[16];
  wire zeroflag = minus[15:0] == 0;



  always @*
  begin
    // Compute the new value of st0
    casez ({fetch, insn[15:8]})

  //  9'b0_011_?0000: st0N = st0;                                   // TOS
      9'b0_011_?0001: st0N = st1;                                   // NOS
      9'b0_011_?0010: st0N = st0 + st1;                             // +
      9'b0_011_?0011: st0N = st0 & st1;                             // and

      9'b0_011_?0100: st0N = st0 | st1;                             // or
      9'b0_011_?0101: st0N = st0 ^ st1;                             // xor
      9'b0_011_?0110: st0N = ~st0;                                  // invert
      9'b0_011_?0111: st0N = {16{zeroflag}};                        //  =

      9'b0_011_?1000: st0N = {16{signedless}};                      //  <
      9'b0_011_?1001: st0N = {st0[15], st0[15:1]};                  // 1 arshift
      9'b0_011_?1010: st0N = {st0[14:0], 1'b0};                     // 1 lshift
      9'b0_011_?1011: st0N = rst0;                                  // r@

      9'b0_011_?1100: st0N = minus[15:0];                           // -
      9'b0_011_?1101: st0N = io_din;                                // Read IO
      9'b0_011_?1110: st0N = {12'b0, dsp};                          // depth
      9'b0_011_?1111: st0N = {16{unsignedless}};                    // u<

  //  9'b0_000_?????: st0N = st0;                                   // Jump
  //  9'b0_010_?????: st0N = st0;                                   // Call
      9'b0_001_?????: st0N = st1;                                   // Conditional jump

      9'b0_1??_?????: st0N = { 1'b0, insn[14:0] };                  // Literal
      9'b1_???_?????: st0N = insn;                                  // Memory fetch

      default: st0N = st0;
    endcase
  end

  wire func_T_N =   (insn[6:4] == 1);
  wire func_T_R =   (insn[6:4] == 2);
  wire func_write = (insn[6:4] == 3);
  wire func_iow =   (insn[6:4] == 4);
  wire func_ior =   (insn[6:4] == 5);
  wire func_dint =  (insn[6:4] == 6);
  wire func_eint =  (insn[6:4] == 7);

  wire is_alu = notreboot & !fetch & (insn[15:13] == 3'b011);

  assign mem_wr = is_alu & func_write;
  assign io_wr  = is_alu & func_iow;
  assign io_rd  = is_alu & func_ior;
  assign io_dout   = st1;

  wire eint = is_alu & func_eint;
  wire dint = is_alu & func_dint;

  wire interrupt_enableN =                   (interrupt_enable | eint) & ~(dint | interrupt); // Disable interrups on IRQ entry.
  wire interrupt_enableN_return = (rst0[15] | interrupt_enable | eint) & ~(dint | interrupt); // Reenable interrupts on return stack MSB.

  // Value which could be written to return stack: Either return address in case of a call or TOS.
  assign rstkD = (insn[13] == 1'b0) ? pc_plus_2 : st0;

  always @*
  begin
    casez ({fetch, insn[15:13]})                          // Calculate new data stack pointer
    4'b1_???,
    4'b0_1??:   {dstkW, dspI} = {1'b1,      2'b01};          // Memory Fetch & Literal
    4'b0_001:   {dstkW, dspI} = {1'b0,      2'b11};          // Conditional jump
    4'b0_011:   {dstkW, dspI} = {func_T_N,  {insn[1:0]}};    // ALU
    default:    {dstkW, dspI} = {1'b0,      2'b00};          // Default: Unchanged
    endcase
    dspN = dsp + {dspI[1], dspI[1], dspI};

    casez ({fetch, insn[15:13]})                          // Calculate new return stack pointer
    4'b1_???:   {rstkW, rspI} = {1'b0,      2'b11};          // Memory Fetch, triggered by high address bit set
    4'b0_010:   {rstkW, rspI} = {1'b1,      2'b01};          // Call
    4'b0_011:   {rstkW, rspI} = {func_T_R,  insn[3:2]};      // ALU
    default:    {rstkW, rspI} = {1'b0,      2'b00};          // Default: Unchanged
    endcase

    casez ({notreboot, fetch, insn[15:13], insn[7], |st0})   // New address for PC
    7'b0_0_???_?_?:   pcN = 0;                                     // Boot: Start at address zero with interrupts disabled
    7'b1_0_000_?_?,
    7'b1_0_010_?_?,
    7'b1_0_001_?_0:   pcN = {2'b0, insn[12:0], interrupt_enableN}; // Jumps & Calls: Destination address
    7'b1_1_???_?_?,
    7'b1_0_011_1_?:   pcN = {1'b0, rst0[14:1], interrupt_enableN_return}; // Memory Fetch & ALU+exit: Return. Maybe reenable interrupts.
    default:          pcN = { pc_plus_2[15:1], interrupt_enableN}; // Default: Increment PC to next opcode
    endcase
  end

  always @(negedge resetq or posedge clk)
  begin
    if (!resetq) begin
      notreboot <= 0;
      { pc, dsp, st0 } <= 0;
    end else begin
      notreboot <= 1;
      { pc, dsp, st0 }  <= { pcN, dspN, st0N };
    end
  end

endmodule