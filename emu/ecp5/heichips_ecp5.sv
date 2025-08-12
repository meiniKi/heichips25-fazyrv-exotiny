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
localparam CHUNKSIZE = 4;
localparam RES_DLY = 1;

// Invert rst if needed
logic rst_inpt;
assign rst_inpt = rst_board;

// Divide further for testing
logic clk_inter;
logic [3:0] clk_cnt = 0;

logic locked;
logic clk_sys;

`ifdef ULX3S
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
  assign clk_sys = clk_inter;

  //always @(posedge clk_inter) begin
  //  clk_cnt <= clk_cnt + 'b1;
  //end
  //
  //assign clk_sys = clk_cnt[1];
`else
  assign clk_inter = clk_i;

  always_ff @(posedge clk_inter) clk_cnt <= clk_cnt + 'b1;
  assign clk_sys = clk_cnt[1];  // 1/4
  assign locked     = 1'b1;
`endif


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

`ifdef ECP5
BB buf0 (.I(muxed_sdo[0]), .T(~muxed_sdoen[0]), .O(core_sdi[0]), .B(qspi_sdio_io[0]));
BB buf1 (.I(muxed_sdo[1]), .T(~muxed_sdoen[1]), .O(core_sdi[1]), .B(qspi_sdio_io[1]));
BB buf2 (.I(muxed_sdo[2]), .T(~muxed_sdoen[2]), .O(core_sdi[2]), .B(qspi_sdio_io[2]));
BB buf3 (.I(muxed_sdo[3]), .T(~muxed_sdoen[3]), .O(core_sdi[3]), .B(qspi_sdio_io[3]));
`else
assign qspi_sdio_io[0] = muxed_sdoen[0] ? muxed_sdo[0] : 1'bz;
assign qspi_sdio_io[1] = muxed_sdoen[1] ? muxed_sdo[1] : 1'bz;
assign qspi_sdio_io[2] = muxed_sdoen[2] ? muxed_sdo[2] : 1'bz;
assign qspi_sdio_io[3] = muxed_sdoen[3] ? muxed_sdo[3] : 1'bz;
assign core_sdi = qspi_sdio_io;
`endif

logic [7:0] chip_ui_in_wire;
logic [7:0] chip_uo_out_wire;
logic [7:0] chip_uio_in_wire;
logic [7:0] chip_uio_out_wire;
logic [7:0] chip_uio_oe_wire;

logic chip_ena_wire;

logic [CHUNKSIZE-1:0] ccx_rs_a;
logic [CHUNKSIZE-1:0] ccx_rs_b;
logic [CHUNKSIZE-1:0] ccx_res;

logic                 ccx_req;
logic                 ccx_resp;

logic                 ccx_sel;


// CCX
// This is used to emulate a custom instruction if present
//
logic [6:0]  tst_dly;

always_ff @(posedge clk_sys) tst_dly <= {tst_dly[5:0], ccx_req};

assign ccx_res = ccx_rs_a & ccx_rs_b;
assign ccx_resp = tst_dly[6];

// Reverse Mappaing to test from top-level interface
//
assign chip_ui_in_wire[7]   = spi_sdi_i;
assign chip_ui_in_wire[6:4] = gpi_i[5:3];
assign chip_ui_in_wire[3:0] = ccx_res;

assign chip_uio_in_wire[7:5]  = gpi_i[2:0];
assign chip_uio_in_wire[4]    = ccx_resp;
assign chip_uio_in_wire[3:0]  = core_sdi;

assign chip_ena_wire    = 1'b0; // todo: another input?

assign ccx_rs_a = chip_uo_out_wire[3:0];
assign ccx_rs_b = chip_uo_out_wire[7:4];

assign core_sdo = { chip_uio_out_wire[5], chip_uio_out_wire[4], 
                    chip_uio_out_wire[2], chip_uio_out_wire[1]};

assign core_cs_rom    = chip_uio_out_wire[0];
assign qspi_cs_ram_on = chip_uio_out_wire[6];
assign core_sck       = chip_uio_out_wire[3];

assign gpo_o = chip_uio_out_wire[7];

assign ccx_sel    = chip_uio_oe_wire[0];
assign core_sdoen = chip_uio_oe_wire[4:1];
assign ccx_req    = chip_uio_oe_wire[5];

assign spi_sck_o = chip_uio_oe_wire[6];
assign spi_sdo_o = chip_uio_oe_wire[7];

//
// 

heichips25_fazyrv_exotiny i_heichips25_fazyrv_exotiny (
  .ui_in    ( chip_ui_in_wire   ),
  .uo_out   ( chip_uo_out_wire  ),
  .uio_in   ( chip_uio_in_wire  ),
  .uio_out  ( chip_uio_out_wire ),
  .uio_oe   ( chip_uio_oe_wire  ),
  .ena      ( chip_ena_wire     ),
  .clk      ( clk_sys           ),
  .rst_n    ( rst_n             )
);


endmodule
