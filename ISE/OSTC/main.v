`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name   : Open Source Turbo Card (OSTC)
// Project Desc   : Acorn Electron Turbo Card
// Start Date     : 17/06/2019 
// Last Modified  : 30/12/2020
// Language       : Verilog
// Target         : XC9536XL-QFP44-10
// IDE		 	   : Xilinx ISE 14.7
// Creator        : G. Colville (ramtop-retro.uk)
//
// Note			   : Basic Electron turbo board, 2MHz / 32KB
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////

module ostc(
	input  [15:12] cpu_address,
	input  cpu_rw,
	input  cpu_clk_in,
	input  turbo_switch,
	output cpu_clk_out,
	output ula_a14,
	output ula_a15,
	output ula_rw,
	output sram_oe,
	output sram_we,
	output sram_ce,
	output sram_a13,
	output sram_a14,
	inout  [7:0]ula_data,
	inout  [7:0]cpu_data
    );

wire fast_read_enable;
wire fast_write_enable;
wire fake_rom_read;

// CPU speed state
reg turbo_state;


// Check if the CPU is accessing the 0-12K low memory area. Could probably concatenate these into one for both R and W, but 
// this is clearer, imho
assign fast_read_enable  = (cpu_rw == 1 && (cpu_address[15:12] == 4'b0000 || cpu_address[15:12] == 4'b0001 || cpu_address[15:12]  == 4'b0010)) ? 1 : 0;
assign fast_write_enable = (cpu_rw == 0 && (cpu_address[15:12] == 4'b0000 || cpu_address[15:12] == 4'b0001 || cpu_address[15:12]  == 4'b0010)) ? 1 : 0;


// If 0-12K access, set fake_rom_read to, well, fake a ROM read so the CPU is driven at 2MHz
assign fake_rom_read = (fast_read_enable == 1 || fast_write_enable == 1) ? 1 : 0;


// If fake_rom_read is set pull A14, A15 and RW high on the ULA side, else just pass them through from the CPU
assign ula_a14 = (fake_rom_read == 1 && turbo_state == 1) ? 1 : cpu_address[14];
assign ula_a15 = (fake_rom_read == 1 && turbo_state == 1) ? 1 : cpu_address[15];
assign ula_rw  = (fake_rom_read == 1 && turbo_state == 1) ? 1 : cpu_rw;


// Pass CPU A13/14 to the SRAM when necessary
assign sram_a13 = (fake_rom_read == 1) ? cpu_address[13] : 0;
assign sram_a14 = (fake_rom_read == 1) ? cpu_address[14] : 0;


// Assert OE or WE when doing read or write cycle to SRAM
assign sram_ce = 0;
assign sram_oe = (fake_rom_read == 1 && cpu_rw == 1 && cpu_clk_out == 1) ? 0 : 1;
assign sram_we = (fake_rom_read == 1 && cpu_rw == 0 && cpu_clk_out == 1) ? 0 : 1;


// Only let data pass from CPU to motherboard and vice versa when CPU is accessing > 12K and the CPU
// clock is high. High-Z the bus at other times
assign cpu_data = (cpu_rw == 1'b1 && cpu_clk_out == 1 && fake_rom_read == 0) ? ula_data : 8'bzzzzzzzz;
assign ula_data = (cpu_rw == 1'b0 && cpu_clk_out == 1 && fake_rom_read == 0) ? cpu_data : 8'bzzzzzzzz;


// Pass the CPU clock though the CPLD. Should probably do this on the PCB as it's not necessary when
// using the ULA generated clock all the time
assign cpu_clk_out = cpu_clk_in;


// Latch turbo switch when CPU clock is low
always @(negedge cpu_clk_in)
	turbo_state <= turbo_switch;

endmodule
