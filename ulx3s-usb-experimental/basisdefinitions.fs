
\ #######   MEMORY   ##########################################

: unused
    $4000 here -
;

\ #######   Flash   ###########################################

\ Save memory image to SPI Flash

: waitspi ( -- )
  begin
    $05 >spi \ Read status register 1
    spi> not 1 and
    idle
  until
;

: spiwe ( -- )
    $06 >spi \ Write enable
    idle
;

: erase ( sector -- )
  dup 29 u> if \ Never overwrite bitstream in sectors 0 to 29.
    idle
    spiwe
    $D8 >spi \ Sector erase
        >spi  \ Sector number
    $00 >spi   \ Address high
    $00 >spi    \ Address low
    idle
    waitspi
  else drop then
;

: save ( sector -- )
  dup 29 u> if \ Never overwrite bitstream in sectors 0 to 29.

    dup erase
    0      \ 8 kb in 256 byte pages
    begin
      spiwe

      $02 >spi \ Page program, 256 Bytes
     over >spi  \ Sector number
     dup
 8 rshift >spi   \ Address high
      $00 >spi    \ Address low

      begin
        dup c@ >spi
        1+
        dup $FF and 0=
      until

      idle
      waitspi

      dup $4000 =
    until
    2drop

  else drop then \ Bitstream protection
;

\ #######   IO   ##############################################

$0104 constant P1IN    \ Input
$0108 constant P1OUT   \ Output
$0110 constant P1DIR   \ Direction
$0120 constant P1IFG   \ Interrupt Flag
$0140 constant P1IES   \ Interrupt Edge Select
$0180 constant P1IE    \ Interrupt Enable

$0204 constant P2IN
$0208 constant P2OUT
$0210 constant P2DIR
$0220 constant P2IFG
$0240 constant P2IES
$0280 constant P2IE

$0404 constant P3IN
$0408 constant P3OUT
$0410 constant P3DIR
$0420 constant P3IFG
$0440 constant P3IES
$0480 constant P3IE

$0804 constant P4IN
$0808 constant P4OUT
$0810 constant P4DIR
$0820 constant P4IFG
$0840 constant P4IES
$0880 constant P4IE

$8004 constant IRQ-CAUSE
$8008 constant IRQ-ENABLE


: ms   ( u -- ) 0 do 4800 0 do loop loop ; \ 10 cycles per loop run. 1 ms * 48 MHz / 10
: leds ( x -- ) $2010 io! ;

: buttons ( -- x ) $2020 io@ ;

: now   ( -- ) 0 $4000 io! ;
: ticks ( -- u ) $4000 io@ ;
: delay ( u -- ) begin dup ticks u< until drop ;

: randombit ( -- 0 | 1 ) $2000 io@ 2 rshift 1 and ;
: random ( -- x ) 0  16 0 do 2* randombit or 100 0 do loop loop ;
