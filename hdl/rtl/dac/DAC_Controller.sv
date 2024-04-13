`timescale 1ns / 1ps

module DAC_Controller (
    input logic [11:0] r1,
    input logic [11:0] r2,
    input logic clk100,
    output logic cs,
    output logic sclk,
    output logic sdi,
    output logic ldac
);
    logic sck;
    logic four_mega;
    
    DivideByN #(.N(25), .M(5)) divide_by_25 (
        .clk(clk100),
        .pulse(four_mega)
    );
    
    always_ff @(posedge four_mega) begin
        sck <= !sck;
    end
    
    parameter RESET = 4'd0, CS_LOW1 = 4'd1, CS_HIGH1 = 4'd2, CS_LOW2 = 4'd3,
              CS_HIGH2 = 4'd4, LDAC_LOW = 4'd5, LDAC_HIGH = 4'd6, NOP = 4'd7;
    
    logic [3:0] counter;
    logic [3:0] state = RESET;
    
    always_ff @(negedge sck) begin
        case (state)
            RESET: begin
                state <= CS_LOW1;
                counter <= 4'd15;
            end
            CS_LOW1: begin
                if (counter == 4'd0)
                    state <= CS_HIGH1;
                else
                    counter <= counter - 1;
            end
            CS_HIGH1: begin
                if (counter == 4'd1) begin
                    state <= CS_LOW2;
                    counter <= 4'd15;
                end else
                    counter <= counter + 1;
            end
            CS_LOW2: begin
                if (counter == 4'd0)
                    state <= CS_HIGH2;
                else
                    counter <= counter - 1;
            end
            CS_HIGH2: begin
                if (counter == 4'd1) begin
                    state <= LDAC_LOW;
                    counter <= 4'd15;
                end else
                    counter <= counter + 1;
            end
            LDAC_LOW: begin
                state <= LDAC_HIGH;
            end
            LDAC_HIGH: begin
                state <= NOP;
            end
            NOP: begin
                state <= RESET;
            end
            default: begin
                state <= RESET;
            end
        endcase
    end
    
    logic [15:0] reg1 = {4'b0011, r1};
    logic [15:0] reg2 = {4'b1011, r2};
    
    always_comb begin
        case (state)
            RESET: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
            CS_LOW1: begin
                cs <= 1'b0;
                ldac <= 1'b1;
                sdi <= reg1[counter];
            end
            CS_HIGH1: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
            CS_LOW2: begin
                cs <= 1'b0;
                ldac <= 1'b1;
                sdi <= reg2[counter];
            end
            CS_HIGH2: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
            LDAC_LOW: begin
                cs <= 1'b1;
                ldac <= 1'b0;
                sdi <= 1'bz;
            end
            LDAC_HIGH: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
            NOP: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
            default: begin
                cs <= 1'b1;
                ldac <= 1'b1;
                sdi <= 1'bz;
            end
        endcase
    end
    
    assign sclk = sck;
    
endmodule