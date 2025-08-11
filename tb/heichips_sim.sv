// Author: Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  heichips_sim.sv
// Usage :  Simulation wrapper HeiChips25 tapeout.
// -----------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module heichips_sim (
  input  logic              clk_i,
  input  logic              rst_in
);

localparam RAMSIZE = 1024*1024*16;
localparam CHUNKSIZE = 4;

// QSPI
logic       cs_ram_n;
logic       cs_rom_n;
logic       sck;
logic [3:0] core_sdo;
logic [3:0] core_sdoen;

// SPI
logic       spi_sck;
logic       spi_sdo;
logic       spi_sdi;

// GPIO
logic [5:0] gpi;
logic gpo;


wire [3:0] sdio;
assign sdio[0] = core_sdoen[0] ? core_sdo[0] : 1'bz;
assign sdio[1] = core_sdoen[1] ? core_sdo[1] : 1'bz;
assign sdio[2] = core_sdoen[2] ? core_sdo[2] : 1'bz;
assign sdio[3] = core_sdoen[3] ? core_sdo[3] : 1'bz;


spiflash i_spiflash (
  .csb ( cs_rom_n ),
  .clk ( sck      ),
  .io0 ( sdio[0]  ),
  .io1 ( sdio[1]  ),
  .io2 ( sdio[2]  ),
  .io3 ( sdio[3]  )
);

qspi_psram #( .DEPTH(RAMSIZE) ) i_qspi_psram (
  .sck_i    ( sck       ),
  .cs_in    ( cs_ram_n  ),
  .io0_io   ( sdio[0]   ),
  .io1_io   ( sdio[1]   ),
  .io2_io   ( sdio[2]   ),
  .io3_io   ( sdio[3]   )
);

logic [7:0] chip_ui_in_wire;
logic [7:0] chip_ui_uo_out_wire;
logic [7:0] chip_uio_in_wire;
logic [7:0] chip_uio_out_wire;
logic [7:0] chip_uio_oe_in_wire;
logic       chip_ena_wire;


// Test custom instruction
//
localparam RES_DLY = 5;

logic [CHUNKSIZE-1:0] ccx_rs_a;
logic [CHUNKSIZE-1:0] ccx_rs_b;
logic [CHUNKSIZE-1:0] ccx_res;

logic                 ccx_req;
logic                 ccx_resp;

logic                 ccx_sel;

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

assign ccx_res  = shift_res[RES_DLY-1];
assign ccx_resp = shift_req[RES_DLY-1 + 32/CHUNKSIZE-1];


// This mapping needs to be done in the eFPGA
//
assign chip_ui_in_wire    = {spi_sdi, gpi[5:3], ccx_res};
assign chip_uio_in_wire   = {gpi[2:0], ccx_resp, sdio};
assign chip_ena_wire      = 1'b0; // todo: another input?

assign ccx_rs_a = chip_ui_uo_out_wire[3:0];
assign ccx_rs_b = chip_ui_uo_out_wire[7:4];

assign core_sdo = { chip_uio_out_wire[5], chip_uio_out_wire[4], 
                    chip_uio_out_wire[2], chip_uio_out_wire[1]};

assign cs_rom_n = chip_uio_out_wire[0];
assign cs_ram_n = chip_uio_out_wire[6];
assign sck      = chip_uio_out_wire[3];

assign gpo = chip_uio_out_wire[7];

assign ccx_sel = chip_uio_oe_in_wire[0];
assign core_sdoen = chip_uio_oe_in_wire[4:1];
assign ccx_req = chip_uio_oe_in_wire[5];

assign spi_sck = chip_uio_oe_in_wire[6];
assign spi_sdo = chip_uio_oe_in_wire[7];


//

heichips25_fazyrv_exotiny i_heichips25_fazyrv_exotiny (
    .ui_in    ( chip_ui_in_wire     ),
    .uo_out   ( chip_ui_uo_out_wire ),
    .uio_in   ( chip_uio_in_wire    ),
    .uio_out  ( chip_uio_out_wire   ),
    .uio_oe   ( chip_uio_oe_in_wire ),
    .ena      ( chip_ena_wire       ),
    .clk      ( clk_i               ),
    .rst_n    ( rst_in              )
);


// conditional loopback for testing
assign spi_sdi =  gpo ? 1'b0 : spi_sdo;

assign gpi =  gpo ? 6'b10_1010 : 6'b01_0101;

endmodule

