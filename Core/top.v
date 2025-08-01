`timescale 1ns / 1ps
// Description: Real-time processing of audio from Line In to Line Out of a Pmod I2S2 on port JA

module top #(
	parameter NUMBER_OF_SWITCHES = 4,
	parameter RESET_POLARITY = 0
) (
    input wire       clk,
    input wire [NUMBER_OF_SWITCHES-1:0] sw,
    input wire       reset,
    
    output wire tx_mclk,
    output wire tx_lrck,
    output wire tx_sclk,
    output wire tx_data,
    output wire rx_mclk,
    output wire rx_lrck,
    output wire rx_sclk,
    input  wire rx_data
);
    reg axis_clk;
    
    wire [23:0] axis_tx_data;
    wire axis_tx_valid;
    wire axis_tx_ready;
    wire axis_tx_last;
    
    wire [23:0] axis_rx_data;
    wire axis_rx_valid;
    wire axis_rx_ready;
    wire axis_rx_last;

	wire resetn = (reset == RESET_POLARITY) ? 1'b0 : 1'b1;

    reg [2:0] count;    
    always @(posedge clk) begin
        count <= count + 1;
        if(count == 3) begin
            count <= 0;
            axis_clk <= ~axis_clk;
        end
    end

    axis_i2s2 m_i2s2 (
        .axis_clk(axis_clk),
        .axis_resetn(resetn),
    
        .tx_axis_s_data(axis_tx_data),
        .tx_axis_s_valid(axis_tx_valid),
        .tx_axis_s_ready(axis_tx_ready),
        .tx_axis_s_last(axis_tx_last),
    
        .rx_axis_m_data(axis_rx_data),
        .rx_axis_m_valid(axis_rx_valid),
        .rx_axis_m_ready(axis_rx_ready),
        .rx_axis_m_last(axis_rx_last),
        
        .tx_mclk(tx_mclk),
        .tx_lrck(tx_lrck),
        .tx_sclk(tx_sclk),
        .tx_sdout(tx_data),
        .rx_mclk(rx_mclk),
        .rx_lrck(rx_lrck),
        .rx_sclk(rx_sclk),
        .rx_sdin(rx_data)
    );

    single_channel_fir_filter #(
		.DATA_WIDTH(24)
	) 
	m_fir (
        .clk(axis_clk),
        .modes(sw),
        
        .fpga_data(axis_rx_data),
        .fpga_valid(axis_rx_valid),
        .fpga_ready(axis_rx_ready),
        .fpga_last(axis_rx_last),
        
        .pmod_data(axis_tx_data),
        .pmod_valid(axis_tx_valid),
        .pmod_ready(axis_tx_ready),
        .pmod_last(axis_tx_last)
    );
endmodule
