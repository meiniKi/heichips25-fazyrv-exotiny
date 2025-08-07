// SPDX-FileCopyrightText: © 2025 Meinhard Kissich
// SPDX-License-Identifier: Apache-2.0

// Adapted from the Tiny Tapeout template

`default_nettype none

module heichips25_fazyrv_exotiny (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // NOT TT compatible!

  localparam CHUNKSIZE = 4;

  logic       cs_rom_n;
  logic       cs_ram_n;

  logic       gpo;
  logic [5:0] gpi;

  logic       spi_sck;
  logic       spi_sdo;
  logic       spi_sdi;

  logic       sck;
  logic [3:0] sdi;
  logic [3:0] sdo;
  logic [3:0] sdoen;

  logic [CHUNKSIZE-1:0] ccx_rs_a;
  logic [CHUNKSIZE-1:0] ccx_rs_b;
  logic [CHUNKSIZE-1:0] ccx_res;
  logic                 ccx_req;
  logic                 ccx_resp;
  logic [1:0]           ccx_sel;    // just bit 0 used

  // Reset sync
  // The one additional flop seems to stop detailed routing from converging.
  //logic       rst_sync_n;
  //always_ff @(posedge clk) rst_sync_n <= rst_n;

  // QSPI ROM / RAM interface
  // on purpose additional tristate IOs are avoided
  assign uio_out[0] = cs_rom_n;
  assign uio_out[1] = sdo[0];
  assign uio_out[2] = sdo[1];
  assign uio_out[3] = sck;
  assign uio_out[4] = sdo[2];
  assign uio_out[5] = sdo[3];
  assign uio_out[6] = cs_ram_n;

  assign uio_oe[1] = sdoen[0];
  assign uio_oe[2] = sdoen[1];
  assign uio_oe[3] = sdoen[2];
  assign uio_oe[4] = sdoen[3];

  assign sdi = {uio_in[3], uio_in[2], uio_in[1], uio_in[0]};

  // ccx
  assign uo_out[3:0]  = ccx_rs_a;
  assign uo_out[7:4]  = ccx_rs_b;
  assign uio_oe[5]    = ccx_req; 

  assign ccx_res    = ui_in[3:0];
  assign ccx_resp   = uio_in[4];
  assign uio_oe[0]  = ccx_sel[0];

  // spi
  assign uio_oe[6] = spi_sck;
  assign uio_oe[7] = spi_sdo;
  assign spi_sdi   = ui_in[7];

  // gpi/0
  assign uio_out[7] = gpo;
  assign gpi[5:0]   = {ui_in[6:4], uio_in[7:5]}; 

  exotiny i_exotiny (
    .clk_i          ( clk       ),
    .rst_in         ( rst_n     ),

    .gpi_i          ( gpi       ),
    .gpo_o          ( gpo       ),

    .mem_cs_ram_on  ( cs_ram_n  ),
    .mem_cs_rom_on  ( cs_rom_n  ),
    .mem_sck_o      ( sck       ),
    .mem_sd_i       ( sdi       ),
    .mem_sd_o       ( sdo       ),
    .mem_sd_oen_o   ( sdoen     ),

    .spi_sck_o      ( spi_sck   ),
    .spi_sdo_o      ( spi_sdo   ),
    .spi_sdi_i      ( spi_sdi   ),

    .ccx_rs_a_o     ( ccx_rs_a  ),
    .ccx_rs_b_o     ( ccx_rs_b  ),
    .ccx_res_i      ( ccx_res   ),
    .ccx_sel_o      ( ccx_sel   ),
    .ccx_req_o      ( ccx_req   ),
    .ccx_resp_i     ( ccx_resp  )
);

endmodule
