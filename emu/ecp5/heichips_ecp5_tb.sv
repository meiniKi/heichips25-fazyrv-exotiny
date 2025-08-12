// Author: Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  heichips_ecp5_tb.sv
// Usage :  Simulation wrapper for ECP5 top-level.
// -----------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module heichips_ecp5_tb;

logic clk   = 1'b0;
logic rst_n = 1'b0;

always #10 clk = ~clk;

initial begin
  rst_n <= 1'b0;
  repeat (1000) @(posedge clk);
  rst_n <= 1'b1;
end

initial begin
  $dumpfile("tb.vcd");
  $dumpvars(0, heichips_ecp5_tb);
end

// QSPI
logic       cs_ram_n;
logic       cs_rom_n;
logic       sck;
wire [3:0]  sdio;

// SPI
logic       spi_sck;
logic       spi_sdo;
logic       spi_sdi;

// GPIO
(* keep *) logic led_rst_n;
(* keep *) logic [5:0] gpi;
(* keep *) logic gpo;

//

spiflash i_spiflash (
  .csb ( cs_rom_n ),
  .clk ( sck      ),
  .io0 ( sdio[0]  ),
  .io1 ( sdio[1]  ),
  .io2 ( sdio[2]  ),
  .io3 ( sdio[3]  )
);

localparam RAMSIZE = 1024*1024*16;

qspi_psram #( .DEPTH(RAMSIZE) ) i_qspi_psram (
  .sck_i    ( sck       ),
  .cs_in    ( cs_ram_n  ),
  .io0_io   ( sdio[0]   ),
  .io1_io   ( sdio[1]   ),
  .io2_io   ( sdio[2]   ),
  .io3_io   ( sdio[3]   )
);


heichips_ecp5 i_heichips_ecp5 (
  .clk_i            ( clk       ),
  .rst_board        ( rst_n     ),
  .led_rst_on       ( led_rst_n ),
  .qspi_cs_ram_on   ( cs_ram_n  ),
  .qspi_cs_rom_on   ( cs_rom_n  ),
  .qspi_sck_o       ( sck       ),
  .qspi_sdio_io     ( sdio      ),
  .spi_sck_o        ( spi_sck   ),
  .spi_sdo_o        ( spi_sdo   ),
  .spi_sdi_i        ( spi_sdi   ),
  .gpi_i            ( gpi       ),
  .gpo_o            ( gpo       )
);

endmodule
