//This is verilog which is shared by both the verilator simulator
//And the pico-ice synthesis. 


// ######   Processor   #####################################
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


  //Data in can be from spi, or from uarts. 
  assign io_din =
    (io_addr[0] ? dataIn : 16'd0) |
    (io_addr[12] ? { 8'd0, uart0_data}                                              : 16'd0) |
    (io_addr[13] ? {14'd0, uart0_valid, !uart0_busy}                                : 16'd0) 
;
 

  // ######   SPI   ##########################################
   wire	       masterChipSelectN;
   wire        writeSPI;
   wire	       MOSI;
   wire [15:0] dataIn;
   
   assign writeSPI =  io_wr & io_addr[3];
   
   wire	       isWrite;
   assign isWrite = (io_addr == 16'h0001);
   
 
SpiOut spiOut (
              .clock(clk),
	      .masterChipSelectN(masterChipSelectN),
	      .data(io_dout),
              .writeSPI(writeSPI), 
	      .MOSI(MOSI));

SpiIn spiIn (
      .clock(clk),
      .MOSI(MOSI),
      .slaveChipSelectN(masterChipSelectN),
      .interrupt(interrupt),
      .data(dataIn));
