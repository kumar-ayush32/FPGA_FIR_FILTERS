`timescale 1ns / 1ps
module single_channel_fir_filter #(
    parameter DATA_WIDTH = 24,
    parameter FILTERS = 4
) (
    input wire clk,
    input wire [FILTERS-1:0] modes,
    
    //AXIS SLAVE INTERFACE
    input  wire [DATA_WIDTH-1:0] fpga_data,
    input  wire fpga_valid,
    input  wire fpga_last,
    output reg  fpga_ready = 1'b1,
    
    // AXIS MASTER INTERFACE
    output reg [DATA_WIDTH-1:0] pmod_data = 1'b0,
    output reg pmod_valid = 1'b0,
    output reg pmod_last = 1'b0,
    input  wire pmod_ready
);
    reg signed [DATA_WIDTH-1:0] input_data [1:0];    // Left and right channel data
    wire signed [DATA_WIDTH-1:0] output_data;    // Combined output data
    
    wire pmod_select = pmod_last;
    wire pmod_new_word = (pmod_valid == 1'b1 && pmod_ready == 1'b1) ? 1'b1 : 1'b0;
    wire pmod_new_packet = (pmod_new_word == 1'b1 && pmod_last == 1'b1) ? 1'b1 : 1'b0;
    
    wire fpga_select = fpga_last;
    wire fpga_new_word = (fpga_valid == 1'b1 && fpga_ready == 1'b1) ? 1'b1 : 1'b0;
    wire fpga_new_packet = (fpga_new_word == 1'b1 && fpga_last == 1'b1) ? 1'b1 : 1'b0;
    reg fpga_new_packet_read = 1'b0;
    
    single_channel_fir_engine fir_engine(
        .clk(clk),
        .sw(modes),
        .new_packet(fpga_new_packet_read),
        .input_data(input_data),
        .output_data(output_data)
    );
    always@(posedge clk) begin
        fpga_new_packet_read <= fpga_new_packet;
        
        if (fpga_new_word == 1'b1) // Register AXIS slave data
            input_data[fpga_select] <= fpga_data;
    end
    
    // Controls the AXIS master interface by setting the validity and end-of-packet signals based on the state of the AXIS slave interface.
    always@(posedge clk)
        if (fpga_new_packet_read == 1'b1)
            pmod_valid <= 1'b1;
        else if (fpga_new_packet == 1'b1)
            pmod_valid <= 1'b0;
            
    always@(posedge clk)
        if (pmod_new_packet == 1'b1)
            pmod_last <= 1'b0;
        else if (pmod_new_word == 1'b1)
            pmod_last <= 1'b1;
    
    // Assigns the output data on the AXIS master interface based on the validity and selection signals.
    always@(pmod_valid, output_data, pmod_select)
        if (pmod_valid == 1'b1)
            pmod_data = output_data;
        else
            pmod_data = 'b0;
            
    always@(posedge clk)
        if (fpga_new_packet == 1'b1)
            fpga_ready <= 1'b0;
        else if (pmod_new_packet == 1'b1)
            fpga_ready <= 1'b1;
endmodule
