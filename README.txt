Acorn Electron Open Source Turbo Card
-------------------------------------

The OSTC is a 'turbo card' that speeds up the Electron by partially mitigating 
the slow memory access that usually limits the 6502 CPU's performance. It acts 
similarly to ye olde turbo cards of days gone by, like the Slogger Turbo Driver, 
but is implemented using modern programmable logic and SRAM.


How it works
------------

Electrons are slow becuase of the ULA stealing RAM cycles to update the
display. When reading from the ROM the CPU works at 2MHz, but when accessing
RAM it runs at 1MHz in modes 4-6. In modes 0-3 the ULA stops the CPU clock
when drawing the display area, effectively throttling the 6502 down to 
around 0.5MHz.

Turbo cards are based on an interesting quirk; the ULA only needs to access
the upper 20K of system RAM for display purposes. The lower 12K is contended
between the ULA and CPU purely to simplify the Electron's design.

The trick is to stop the ULA from contending the lower 12K. We do this by
adding some new memory dedicated to the CPU, in this case a 32K SRAM chip.
All reads and writes to the 0-12K area are redirected to the SRAM chip - old
turbo cards handled the first 8K only to simplify the required logic, be here
we do all 12K. The 6502's databus is passed through the CPLD chip, which sets
it to high impedence when the SRAM is being accessed, effectively preventing
the Elk's on-board DRAM from causing bus contention.

That's great, but we're still not going any faster. The ULA is still throttling
the CPU clock, even when we're now accessing that lovely fast SRAM chip and not
the grotty contended motherboard DRAM.

The solution is to run the CPU's A15, A14 and RW lines through the CPLD. When
the CPU accesses the SRAM chip the CPLD pulls all of those lines high on the
ULA side, fooling it into thinking we are reading from the ROM - the the ULA
duly accelerates the CPU to 2MHz. The actual data read from the ROM never
reaches the CPU as the CPLD acts as a bus isolator at this point, cutting the CPU
and SRAM off from the motherboard.

One major difference between the older turbos and the OSTC is how 
disabling the board is handled. Other boards required a reboot after toggling
the board state. 

The OSTC never actually disables, the switch just returns the CPU to
normal speed. R/W operations are still processed by the SRAM chip, not DRAM.

This has the big advtantage that SRAM contents is always up to date and turbo
speed can be toggled without a reboot. Downside is the very few games that try
to locate the display < 12K won't run.


Files
-----
 - PCB 		PCB layout in Diptrace format
 - Gerbers	Gerber and drill files
 - ISE		Xilinx ISE project (verilog)
 - CPLD		Programming file for the CPLD


How to build it
---------------

In the Gerbers directory is a Zip file you can upload to pretty much any of the
cheap PCB services to have them produce OSTC PCBs for you. The PCB directory has
the original PCB layout file in Diptrace format. (Diptrace is commercial software,
but they do a 30 day trial copy if you want to play around with the design)

The components necessary are:

REF				Component 							Part no.
C1, C2, C3			150pF 1206 size ceramic capacitor				399-8157-1-ND (Digikey)
C4, C5				22uF 1206 size tantalum capacitor				478-3865-1-ND (Digikey)
VR3v3				3.3v LM1117 voltage regulator					LM1117MP-3.3/NOPBCT-ND (Digikey)
R1				2Kohm 1206 resistor						RMCF1206JT2K00CT-ND (Digikey)
R2				4Kohm 1206 resistor						RNCP1206FTD4K02CT-ND (Digikey)
JTAG, SW1, DBG			0.1" pin headers, right-angle					547-3223 (RS Components)
6502				2x Low profile 40-way turned pin socket 			197-2726 (RS Components)
ElkMB				2x 20 way round pin headers (see below)				BBL-120-T-E (Toby Electronics)
XC9500XL			Xilinx XC9536XL 44-pin CPLD					122-1385-ND (Digikey)


The OSTC has been designed to be fairly easy to build if you have some surface mount
soldering experience. A few points to note, however:

- Capacitor and resistor values are not super critical, but C4/5 should be tantalums of
at least 22uF or stability may be affected.
- I strongly recommend using turned pin type sockets, these are much more reliable than
the dual-wipe type, but they absolutely require the round-pin type headers listed above
and not the cheaper, more common, square pin type.
- The JTAG header should be right-angle, with the pins located over the top of the CPLD.
- DBG is the debug header, fitting this is not required

CPU speed is controlled by pins 1 and 2 of SW1. Shorting these pins slows the CPU to stock
speed, open is turbo speed.

JTAG header pinout is :

1 3.3v
2 GND
3 TCK
4 TDO
5 TDI
6 TMS


How to fit it
-------------

Fitting the OSTC requires the Electron's 6502 CPU to be desoldered from the motherboard. It
is strongly recommended you use a proper vacuum desoldering station to do this, or find
someone who can do it for you, as the Elk's PCB is quite fragile.

Once the CPU is removed it should be installed into the socket on the OSTC marked '6502' with
the orientation notch facing away from the JTAG header. Then, solder the remaining 40-pin socket
into the CPU area on the motherboard. Insert the OSTC into the socket, pushing firmly and making
sure it is correctly aligned with the SW1 header facing the rear of the Electron.

If you want to control the CPU speed a switch can be connected between pins 1 and 2 of SW1.

A Rockwell R65C02 rated 2MHz or faster can be fitted in place of the original NMOS 6502, to
reduce heat build-up. WDC branded 65C02s will not work.


License
-------
Copyright for all the files contained in this repository remains with me (G. Colville) but
they can be freely used for non-commercial purposes.

