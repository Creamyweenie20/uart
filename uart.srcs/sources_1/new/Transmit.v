`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 07:50:08 PM
// Design Name: 
// Module Name: Transmit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Transmit #(parameter BUSWIDTH = 8, parameter CLKS_PER_BIT = 5208)(

    input i_clk,
    input i_rst,
    input i_tx_valid, 
    input [BUSWIDTH - 1: 0] i_tx_byte,
    output o_tx_active, 
    output reg o_tx_serial, 
    output o_tx_done
    );
    // Defining states for FSM
    parameter s_IDLE = 3'b000; 
    parameter s_START_BIT = 3'b001; 
    parameter s_DATA_BITS = 3'b010; 
    parameter s_STOP_BIT = 3'b011; 
    parameter s_CLEAN = 3'b100; 
    
    reg [2:0] r_SM_MAIN = 0; 
    reg [7:0] r_Clk_count = 0; 
    reg [2:0] r_bit_index = 0; 
    reg [BUSWIDTH - 1:0] r_tx_data = 0; 
    reg r_tx_done = 0;
    reg r_tx_active = 0; 
    
    always @(posedge i_clk)
        begin 
            case(r_SM_MAIN)
            s_IDLE: 
                begin 
                o_tx_serial <= 1'b1; 
                r_tx_done = 1'b0; 
                r_Clk_count = 0;
                r_bit_index = 0; 
                
                if ( i_tx_valid == 1'b1) begin 
                    r_tx_active = 1'b1; 
                    r_tx_data = i_tx_byte; 
                    r_SM_MAIN <= s_START_BIT; 
                end
                else begin
                    r_SM_MAIN <= s_IDLE; 
                end end 
            s_START_BIT: 
                begin 
                o_tx_serial = 1'b0; 
                if (r_Clk_count < CLKS_PER_BIT - 1) 
                begin
                    r_Clk_count <= r_Clk_count + 1; 
                    r_SM_MAIN <= s_START_BIT; 
                end 
                else
                begin
                    r_Clk_count <= 0;
                    r_SM_MAIN <= s_DATA_BITS; 
                end 
                end
            s_DATA_BITS:
                begin 
                o_tx_serial = i_tx_byte[r_bit_index];
                
                if (r_Clk_count < CLKS_PER_BIT - 1)
                begin
                    r_Clk_count <= r_Clk_count + 1; 
                    r_SM_MAIN <= s_DATA_BITS; 
                end 
                else begin
                    r_Clk_count <= 0 ;
                    
                    if (r_bit_index < BUSWIDTH -1) 
                    begin 
                        r_bit_index = r_bit_index + 1; 
                        r_SM_MAIN <= s_DATA_BITS; 
                    end 
                    else 
                    begin 
                        r_bit_index <= 0; 
                        r_SM_MAIN <= s_STOP_BIT; 
                    end
                    end
                end 
            s_STOP_BIT: 
                begin 
                    o_tx_serial <= 1'b0;
                    if (r_Clk_count < CLKS_PER_BIT - 1) 
                    begin 
                        r_Clk_count <= r_Clk_count + 1; 
                        r_SM_MAIN <= s_STOP_BIT; 
                    end
                    else begin 
                        r_tx_done <= 1'b1; 
                        r_Clk_count <= 0; 
                        r_SM_MAIN <= s_CLEAN; 
                        r_tx_active <= 1'b0;
                    end
                end
            
            s_CLEAN: 
                begin
                    r_tx_done <= 1'b1; 
                    r_SM_MAIN <= s_IDLE;
                end                
                
            default: 
                r_SM_MAIN <= s_IDLE; 
            
            endcase
        end
    
    assign o_tx_done = r_tx_done; 
    assign o_tx_active = r_tx_active; 
    
endmodule
