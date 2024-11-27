# Mecrisp-Pi

Mecrisp Pi is a stack based FPGA co-processor, and Forth interpreter, 
for the RP2040 and RP2350 chips
running on the
[Pico-Ice](https://tinyvision.ai/products/pico-ice-fpga-trainer-board)
and (soon) [Pico2-Ice](https://discord.gg/4X6caMbHCD) circuit boards.
Mecrisp Pi provides the firmware, Verilog and Forth to connect the two chips.

There are many differrent things you can build with Mecrisp-Pi:
- Data Filters such as PDM to PCM.  
- an RP2040/2350 coprocessor using the 8 FPGA DSP blocks.
- a Jupiter Ace style Forth Computer.
- real time controller with many more I/O ports.
- very complex I/O devices.

The newer RP2350 chip in the pico2-ice can drive an DVI/HDMI display. 
Additional peripherals can be added with the
pre-soldered pmods, no need to learn how to solder. The [Mecrisp Ice
Interpreter](https://mecrisp-ice.readthedocs.io/en/latest/api.html)
makes it much easier to debug your hardware designs.   

Forth on the FPGA can access resources running on both cores of the RP chip.
For example, MicroPython libaries can be used to drive the display. 
There are PIO programs which can act as USB host devices.  There is 
software to run a FAT file system on the RP chip's FLASH, which 
can then be accessed from Forth on the FPGA. The ICE40 also has its own Flash which 
can be used for a block based file system. 

The ICE40UP5k FPGA can also be used to accelerate parallel
processes, or provides another 32 GPIO ports.   4 PMODS ports are available
for additional functionality. For example, a Diligent I2S2 PMOD can
provide stereo audio I/O.

This repository includes:

    Compiled gateware for the J1a for the pico-ice FPGA.

    Verilog definitions as well as additional useful modules in
    ./common-verilog.

    Ready-to-emulate verilator simulators in ./verilator*

    Cross compiler and the definitions of in ./common-crosscompiler.

    An extended version of the Hayes-Forth test suite is located in
    ./testsuite. Some of the documentation is in german.

    Pascal simulator is in ./common-crosscompiler.

## INSTALLATION

You can either just flash the gateware or build it yourself.

### Flash the Gateware

First clone the repository

`git clone https://github.com/PythonLinks/mecrisp-pi`

`cd mecrisp-pi/pico-ice`

To flash the gateware on try:

`sudo dfu-util -a 0 -D j1a.bin`

To talk to the fpga, first you have to find the usb devices. On Ubuntu:

`ls /dev | grep ACM`

If there is `/dev/ttyACM1` then in order to
get proper cr behavior on Ubuntu try:

`picocom --imap crcrlf,lfcrlf /dev/ttyACM1`

On Mac OS X I did

`ls /dev | grep usb`

And then:

`picocom --imap crcrlf,lfcrlf /dev/tty.usbmodem1103`

But I think that the current release of the pico-ice-sdk has problems
on Mac Os.  If you really need Mac OS, tell me, and I will try to
debug the pico-ice firmware.  I need it for myself anyhow. 

### Compiling and Synthesizing

First install gForth, freePascal, and OSS cad suite. Then

```
git clone https://github.com/PythonLinks/mecrisp-pi
cd mecrisp-pi
./compile
```

And then follow the above instructions for flashing and connecting.

If you have any problems, please send me an email.
lozinski@PythonLinks.info

Or post an issue here. 

## NOTES

Uart communication works.

This repository does not yet include the firmware and gateware for
spi communication between the RP2040 and the ICE40 FPGA.  The RP2040 side works, I just have to add the FPGA side.  Enjoyable work. SPI send and receive now work in a test bench in the dev branch.  Preogress is fast and enjoyable. 

If you have any questions, please [join the Mecrisp-Pi Discord server](https://discord.gg/DY2HZG5g)

