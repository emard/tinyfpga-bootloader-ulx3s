`default_nettype none
module bootloader_ulx3s (
  input  clk_25mhz,

  inout  usb_fpga_bd_dp,
  inout  usb_fpga_bd_dn,
  output usb_fpga_pu_dp, // full speed usb 11 Mbps
  //output usb_fpga_pu_dn, // low speed usb

  input  [6:0] btn,
  output [7:0] led,

  input  flash_miso,
  output flash_mosi,
  output flash_csn,
  output flash_wpn,
  output flash_holdn,
  
  output user_programn
);

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 mhz clock
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire [3:0] clocks1, clocks2;
  ecp5pll
  #(
      .in_hz(25000000),
    .out0_hz(60000000),                 .out0_tol_hz(0)
    //.out1_hz(50000000), .out1_deg( 90), .out1_tol_hz(0),
    //.out2_hz(60000000), .out2_deg(180), .out2_tol_hz(0),
    //.out3_hz( 6000000), .out3_deg(300), .out3_tol_hz(0)
  )
  ecp5pll_inst1
  (
    .clk_i(clk_25mhz),
    .clk_o(clocks1)
  );

  ecp5pll
  #(
      .in_hz(60000000),
    .out0_hz(48000000),                 .out0_tol_hz(0)
    //.out1_hz(50000000), .out1_deg( 90), .out1_tol_hz(0),
    //.out2_hz(60000000), .out2_deg(180), .out2_tol_hz(0),
    //.out3_hz( 6000000), .out3_deg(300), .out3_tol_hz(0)
  )
  ecp5pll_inst2
  (
    .clk_i(clocks1[0]),
    .clk_o(clocks2)
  );

  wire clk_60mhz = clocks1[0];
  wire clk_48mhz = clocks2[0];

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// instantiate tinyfpga bootloader
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire reset;
  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;

  assign flash_wpn = 1;
  assign flash_holdn = 1;
  
  wire pin_sck;
  wire pin_cs_i;
  assign flash_csn = pin_cs_i;

  wire boot;
  
  tinyfpga_bootloader 
  #(
    .USB_CLOCK_MULT(4) // 48 MHz
    //.USB_CLOCK_MULT(5) // 60 MHz    
  )
  tinyfpga_bootloader_inst
  (
    .clk_usb(clk_48mhz),
    //.clk_usb(clk_60mhz),
    .reset(reset),
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),
    .led(led[0]),
    .spi_miso(flash_miso),
    .spi_cs(pin_cs_i),
    .spi_mosi(flash_mosi),
    .spi_sck(pin_sck),
    .boot(boot)
  );
  
  reg initiate_boot = 0;
  reg [8:0] boot_delay = 0;
  assign user_programn = ~boot_delay[8];
 
  
  always @(posedge clk_25mhz) begin
    if (boot) initiate_boot <= 1;

    if (initiate_boot) begin
		boot_delay <= boot_delay + 1'b1;
    end
  end

  assign usb_fpga_pu_dp = 1'b1;
  //assign usb_fpga_pu_dn = 1'b1;
  assign usb_fpga_bd_dp = usb_tx_en ? usb_p_tx : 1'bz;
  assign usb_fpga_bd_dn = usb_tx_en ? usb_n_tx : 1'bz;
  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_fpga_bd_dp;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_fpga_bd_dn;

  USRMCLK usrmclk_inst (
    .USRMCLKI(pin_sck),
    .USRMCLKTS(pin_cs_i)
  ) /* synthesis syn_noprune=1 */;

  assign reset = ~btn[0];
  assign led[6:1] = 0;
  assign led[7] = reset;
endmodule
`default_nettype wire
