`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2016 03:57:22 PM
// Design Name: 
// Module Name: main
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


module clk_50m_generator(input clk, input reset_clk, output clk_50m);
    reg [1:0] counter;  
    reg clk_reg;
    wire clk_next;
    
    always @(posedge clk, posedge reset_clk)
    if (reset_clk) begin
        clk_reg <= 1'b0;
    end else begin
        clk_reg <= clk_next;
    end
  
    assign clk_next = ~clk_reg;
    assign clk_50m = clk_reg;
endmodule