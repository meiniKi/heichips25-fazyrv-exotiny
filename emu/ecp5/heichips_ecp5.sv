// Author: Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  heichips_ecp5.sv
// Usage :  Emulation wrapper for HeiChips FazyRV ExoTiny CCX
// -----------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module heichips_ecp5 (
  input  logic        clk_i,
  input  logic        rst_board,
  // Debug IOs
  output logic        led_rst_on,
  // QSPI Memory
  output logic        qspi_cs_ram_on,
  output logic        qspi_cs_rom_on,
  output logic        qspi_sck_o,
  inout  logic [3:0]  qspi_sdio_io,

  output logic        spi_sck_o,
  output logic        spi_sdo_o,
  input  logic        spi_sdi_i,
  // GPIO
  input  logic [5:0]  gpi_i,
  output logic        gpo_o
  // ROM Program interface
`ifdef PROG_INTERFACE
  ,
  input  logic        prg_sck_i,
  input  logic        prg_copi_i,
  input  logic        prg_cs_i,
  output logic        prg_cipo_o
`endif

);

localparam CONF = "MIN";

// Invert rst if needed
logic rst_inpt;
assign rst_inpt = rst_board;

// Divide further for testing
logic clk_inter;
logic [3:0] clk_cnt = 0;

logic locked;
logic clk_sys;
logic clk_mem;

(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="100" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
  .PLLRST_ENA       ( "ENABLED"   ),
  .INTFB_WAKE       ( "DISABLED"  ),
  .STDBY_ENABLE     ( "DISABLED"  ),
  .DPHASE_SOURCE    ( "DISABLED"  ),
  .OUTDIVIDER_MUXA  ( "DIVA"      ),
  .OUTDIVIDER_MUXB  ( "DIVB"      ),
  .OUTDIVIDER_MUXC  ( "DIVC"      ),
  .OUTDIVIDER_MUXD  ( "DIVD"      ),
  .CLKI_DIV         ( 6           ),
  .CLKOP_ENABLE     ( "ENABLED"   ),
  .CLKOP_DIV        ( 10          ),
  .CLKOP_CPHASE     ( 4           ),
  .CLKOP_FPHASE     ( 0           ),
  .FEEDBK_PATH      ( "CLKOP"     ),
  .CLKFB_DIV        ( 15          )
) pll_i (
        .RST          ( ~rst_inpt  ),
        .STDBY        ( 1'b0      ),
        .CLKI         ( clk_i     ),
        .CLKOP        ( clk_inter ),
        .CLKFB        ( clk_inter ),
        .CLKINTFB     (           ),
        .PHASESEL0    ( 1'b0      ),
        .PHASESEL1    ( 1'b0      ),
        .PHASEDIR     ( 1'b1      ),
        .PHASESTEP    ( 1'b1      ),
        .PHASELOADREG ( 1'b1      ),
        .PLLWAKESYNC  ( 1'b0      ),
        .ENCLKOP      ( 1'b0      ),
        .LOCK         ( locked    )
);

assign clk_mem = clk_inter;
assign clk_sys = clk_inter;


// --- Reset logic ---
logic [2:0] locked_dly_r = 0;

always @(posedge clk_sys) begin
  if (~locked | ~rst_inpt) begin
    locked_dly_r <= 'b0;
  end else begin
    if (~&locked_dly_r) locked_dly_r <= locked_dly_r + 'b1;
  end
end

logic rst_n;
assign rst_n      = locked & rst_inpt & (&locked_dly_r);
assign led_rst_on = rst_inpt;
// ---- 

wire [3:0] core_sdo;
wire [3:0] core_sdi;
wire [3:0] core_sdoen;

wire [3:0] muxed_sdo;
wire [3:0] muxed_sdoen;

wire core_sck;
wire core_cs_rom;


// Multiplex SPI to Pico if enabled and FPGA in reset
`ifdef PROG_INTERFACE
wire mux_rom_to_pico;
assign mux_rom_to_pico = ~rst_inpt;
assign qspi_sck_o     = mux_rom_to_pico ? prg_sck_i : core_sck;
assign qspi_cs_rom_on = mux_rom_to_pico ? prg_cs_i  : core_cs_rom;
assign muxed_sdoen    = mux_rom_to_pico ? 4'b0001 : core_sdoen;
assign muxed_sdo      = mux_rom_to_pico ? {3'b0, prg_copi_i} : core_sdo;
assign prg_cipo_o     = core_sdi[1];
`else
assign qspi_sck_o     = core_sck;
assign qspi_cs_rom_on = core_cs_rom;
assign muxed_sdoen    = core_sdoen;
assign muxed_sdo      = core_sdo;
`endif


BB buf0 (.I(muxed_sdo[0]), .T(~muxed_sdoen[0]), .O(core_sdi[0]), .B(qspi_sdio_io[0]));
BB buf1 (.I(muxed_sdo[1]), .T(~muxed_sdoen[1]), .O(core_sdi[1]), .B(qspi_sdio_io[1]));
BB buf2 (.I(muxed_sdo[2]), .T(~muxed_sdoen[2]), .O(core_sdi[2]), .B(qspi_sdio_io[2]));
BB buf3 (.I(muxed_sdo[3]), .T(~muxed_sdoen[3]), .O(core_sdi[3]), .B(qspi_sdio_io[3]));

localparam CLK_MEM_FACTOR = 1;

logic [7:0] ui_in;
logic [7:0] uo_out;
logic [7:0] uio_in;
logic [7:0] uio_out;
logic [7:0] uio_oe;

logic ena;

// Reverse Mappaing to test from top-level interface
//

// QSPI Mem
assign qspi_cs_ram_on = uio_out[6];
assign core_cs_rom    = uio_out[0];
assign core_sck       = uio_out[3];
assign core_sdo       = {uio_out[5:4], uio_out[2:1]};
assign core_sdoen     = uio_oe[4:1];

assign uio_in[3:0] = core_sdi;

// SPI
assign spi_sck_o      = uio_oe[6];
assign spi_sdo_o      = uio_oe[7];
assign ui_in[7]       = spi_sdi_i;

// Input
assign ui_in[6:4]     = gpi_i[5:3];
assign uio_in[7:5]    = gpi_i[2:0];

// Output
assign gpo_o          = uio_out[7];

// CCX
// This is used to emulate a custom instruction if present
//
localparam CHUNKSIZE = 4;

logic [CHUNKSIZE-1:0] ccx_rs_a;
logic [CHUNKSIZE-1:0] ccx_rs_b;
logic [CHUNKSIZE-1:0] ccx_res;

logic                 ccx_req;
logic                 ccx_resp;

logic                 ccx_sel;

assign ccx_rs_a = uo_out[3:0];
assign ccx_rs_b = uo_out[7:4];
assign ccx_sel  = uio_oe[0];
assign ccx_req  = uio_oe[5];
assign ccx_res  = shift_res[RES_DLY-1];
assign ccx_resp = shift_req[RES_DLY-1 + 32/CHUNKSIZE-1];


localparam RES_DLY = 5;

logic [CHUNKSIZE-1:0] shift_res [0:RES_DLY-1];
logic                 shift_req [0:(RES_DLY-1 + 32/CHUNKSIZE-1)];

integer i;
always_ff @(posedge clk_i) begin
  shift_res[0] <= ccx_rs_a & ccx_rs_b;
  shift_req[0] <= ccx_req;
  for (i = 1; i < RES_DLY; i = i + 1) begin
      shift_res[i] <= shift_res[i-1];
  end
  for (i = 1; i < RES_DLY + 32/CHUNKSIZE-1; i = i + 1) begin
      shift_req[i] <= shift_req[i-1];
  end
end

//
// 

heichips25_fazyrv_exotiny i_heichips25_fazyrv_exotiny (
  .ui_in    ( ui_in   ),
  .uo_out   ( uo_out  ),
  .uio_in   ( uio_in  ),
  .uio_out  ( uio_out ),
  .uio_oe   ( uio_oe  ),
  .ena      ( ena     ),
  .clk      ( clk_sys ),
  .rst_n    ( rst_n   )
);



endmodule
