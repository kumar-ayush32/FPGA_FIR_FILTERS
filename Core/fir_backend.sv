`timescale 1ns / 1ps
module single_channel_fir_engine #(
    parameter DATA_WIDTH = 24,
    parameter N_FILTERS = 4, // Number of filters implemented
    parameter N_TAPS = 89,
    parameter COEFF_WIDTH = 16
) (
    input wire clk,
    input wire [N_FILTERS-1:0] sw,
    input wire new_packet,
    
    input reg signed [DATA_WIDTH-1:0] input_data [1:0],
    output reg signed [DATA_WIDTH-1:0] output_data,
    
    output reg signed [DATA_WIDTH-1:0] buffer [N_TAPS-1:0],  // Buffer for data
    output reg signed [COEFF_WIDTH+DATA_WIDTH-1:0] op_buffer,
    
    output reg [2:0] selected_filter
);
    // --
   reg signed [COEFF_WIDTH-1:0] coeffs [N_FILTERS-1:0][N_TAPS-1:0] = '{
   '{ // Low-pass filter: 1KHz
        -16'h0006, -16'h0011, -16'h001C, -16'h0027, -16'h0031,
        -16'h003A, -16'h0040, -16'h0041, -16'h003B, -16'h002C,
        -16'h0013, 16'h0011, 16'h003D, 16'h0071, 16'h00A7,
        16'h00DA, 16'h0104, 16'h011C, 16'h011D, 16'h00FF,
        16'h00BF, 16'h005C, -16'h002A, -16'h00CB, -16'h017C,
        -16'h0231, -16'h02D7, -16'h035B, -16'h03A7, -16'h03AA,
        -16'h0351, -16'h028F, -16'h015E, 16'h0043, 16'h024D,
        16'h04B0, 16'h0755, 16'h0A22, 16'h0CF4, 16'h0FA8,
        16'h121B, 16'h142A, 16'h15BA, 16'h16B3, 16'h1707,
        16'h16B3, 16'h15BA, 16'h142A, 16'h121B, 16'h0FA8,
        16'h0CF4, 16'h0A22, 16'h0755, 16'h04B0, 16'h024D,
        16'h0043, -16'h015E, -16'h028F, -16'h0351, -16'h03AA,
        -16'h03A7, -16'h035B, -16'h02D7, -16'h0231, -16'h017C,
        -16'h00CB, -16'h002A, 16'h005C, 16'h00BF, 16'h00FF,
        16'h011D, 16'h011C, 16'h0104, 16'h00DA, 16'h00A7,
        16'h0071, 16'h003D, 16'h0011, -16'h0013, -16'h002C,
        -16'h003B, -16'h0041, -16'h0040, -16'h003A, -16'h0031,
        -16'h0027, -16'h001C, -16'h0011, -16'h0006
    },
    '{ // High pass filter: 2KHz
        16'h0003, 16'h0008, 16'h000E, 16'h0013, 16'h0019,
        16'h001D, 16'h0020, 16'h0020, 16'h001D, 16'h0016,
        16'h0009, -16'h0008, -16'h001F, -16'h0038, -16'h0053,
        -16'h006D, -16'h0082, -16'h008E, -16'h008E, -16'h007F,
        -16'h005F, -16'h002E, 16'h0015, 16'h0065, 16'h00BE,
        16'h0118, 16'h016B, 16'h01AC, 16'h01D2, 16'h01D4,
        16'h01A7, 16'h0147, 16'h00AE, -16'h0022, -16'h0126,
        -16'h0256, -16'h03A8, -16'h050E, -16'h0676, -16'h07CF,
        -16'h0907, -16'h0A0F, -16'h0AD6, -16'h0B52, 16'h7483,
        -16'h0B52, -16'h0AD6, -16'h0A0F, -16'h0907, -16'h07CF,
        -16'h0676, -16'h050E, -16'h03A8, -16'h0256, -16'h0126,
        -16'h0022, 16'h00AE, 16'h0147, 16'h01A7, 16'h01D4,
        16'h01D2, 16'h01AC, 16'h016B, 16'h0118, 16'h00BE,
        16'h0065, 16'h0015, -16'h002E, -16'h005F, -16'h007F,
        -16'h008E, -16'h008E, -16'h0082, -16'h006D, -16'h0053,
        -16'h0038, -16'h001F, -16'h0008, 16'h0009, 16'h0016,
        16'h001D, 16'h0020, 16'h0020, 16'h001D, 16'h0019,
        16'h0013, 16'h000E, 16'h0008, 16'h0003
    },
    '{ // Bandpass: 1KHz to 4KHz
        -16'h0002, -16'h0010, -16'h0017, -16'h0013, 16'h0001,
        16'h0025, 16'h0054, 16'h0086, 16'h00AD, 16'h00BA,
        16'h00A6, 16'h0073, 16'h0031, -16'h0006, -16'h0014,
        16'h001B, 16'h0089, 16'h011D, 16'h01A8, 16'h01EC,
        16'h01B6, 16'h00EE, -16'h0057, -16'h01D6, -16'h032C,
        -16'h03F4, -16'h03EA, -16'h030B, -16'h01A5, -16'h004A,
        16'h0050, -16'h0071, -16'h02D8, -16'h06B4, -16'h0B46,
        -16'h0F67, -16'h11BF, -16'h1127, -16'h0CFB, -16'h055D,
        16'h04C0, 16'h0FB6, 16'h198B, 16'h2059, 16'h22C8,
        16'h2059, 16'h198B, 16'h0FB6, 16'h04C0, -16'h055D,
        -16'h0CFB, -16'h1127, -16'h11BF, -16'h0F67, -16'h0B46,
        -16'h06B4, -16'h02D8, -16'h0071, 16'h0050, -16'h004A,
        -16'h01A5, -16'h030B, -16'h03EA, -16'h03F4, -16'h032C,
        -16'h01D6, -16'h0057, 16'h00EE, 16'h01B6, 16'h01EC,
        16'h01A8, 16'h011D, 16'h0089, 16'h001B, -16'h0014,
        -16'h0006, 16'h0031, 16'h0073, 16'h00A6, 16'h00BA,
        16'h00AD, 16'h0086, 16'h0054, 16'h0025, 16'h0001,
        -16'h0013, -16'h0017, -16'h0010, -16'h0002
    },
       '{ // Band Reject Filter
        16'h0001, 16'h0006, 16'h000A, 16'h000C, 16'h000B, 
        16'h0005, -16'h0008, -16'h001C, -16'h0036, -16'h0054, 
        -16'h0070, -16'h0087, -16'h0092, -16'h008C, -16'h0075, 
        -16'h004C, -16'h0018, 16'h001E, 16'h004B, 16'h0064, 
        16'h0060, 16'h003B, -16'h0004, -16'h0051, -16'h0097, 
        -16'h00BD, -16'h00AA, -16'h004A, 16'h006E, 16'h0178, 
        16'h02C0, 16'h0421, 16'h0568, 16'h065F, 16'h06D0, 
        16'h0691, 16'h058D, 16'h03C6, 16'h015A, -16'h017F, 
        -16'h047B, -16'h0744, -16'h098A, -16'h0B06, 16'h73AD, 
        -16'h0B06, -16'h098A, -16'h0744, -16'h047B, -16'h017F, 
        16'h015A, 16'h03C6, 16'h058D, 16'h0691, 16'h06D0, 
        16'h065F, 16'h0568, 16'h0421, 16'h02C0, 16'h0178, 
        16'h006E, -16'h004A, -16'h00AA, -16'h00BD, -16'h0097, 
        -16'h0051, -16'h0004, 16'h003B, 16'h0060, 16'h0064, 
        16'h004B, 16'h001E, -16'h0018, -16'h004C, -16'h0075, 
        -16'h008C, -16'h0092, -16'h0087, -16'h0070, -16'h0054, 
        -16'h0036, -16'h001C, -16'h0008, 16'h0005, 16'h000B, 
        16'h000C, 16'h000A, 16'h0006, 16'h0001
    }};
    
    always@(posedge clk) begin
        // Update the currently selected filter
        case (sw)
            4'b0000: selected_filter <= 0;
            4'b0001: selected_filter <= 4;
            4'b0010: selected_filter <= 3;
            4'b0100: selected_filter <= 2;
            4'b1000: selected_filter <= 1;
            default: selected_filter <= 0;
        endcase
            
        // Hold the latest input on top of buffer (buffer[N_TAPS - 1])
        if (new_packet == 1'b1) begin // New packet recieved
            buffer[N_TAPS - 1] <= (input_data[0] + input_data[1]) / 2;
        end
    end
            
    generate
    for (genvar i = 0; i < N_TAPS - 1; i = i+1) begin
        always@(posedge clk)
            if (new_packet == 1'b1) begin // New packet recieved
                // Shift the old packets so that buffer[N_TAPS - 1] holds the latest one
                buffer[i]  <= buffer[i + 1];
            end
    end
    endgenerate
    
    // Actually compute the output
    always@(posedge clk)
        if (new_packet == 1'b1 && selected_filter != 0) begin // New packet recieved
            op_buffer = coeffs[selected_filter - 1][0] * buffer[N_TAPS - 1];
            for (int i = 1; i < N_TAPS; i = i+1)
                op_buffer = op_buffer + coeffs[selected_filter - 1][i] * buffer[N_TAPS - i - 1];
            
            
            if (op_buffer[COEFF_WIDTH+DATA_WIDTH-1] == 1'b1)   // If is negative
                output_data = -((-op_buffer) >> COEFF_WIDTH);     // Convert to +ve for shifting
            else output_data <= op_buffer[COEFF_WIDTH+DATA_WIDTH-1:COEFF_WIDTH];
            
        end
        else if (new_packet == 1'b1 && selected_filter == 0)
            output_data <= (input_data[0] + input_data[1]) / 2;
endmodule
