// Spec v1.1
module tpumac
 #(parameter BITS_AB=8,
   parameter BITS_C=16)
  (
   input clk, rst_n, WrEn, en,
   input signed [BITS_AB-1:0] Ain,
   input signed [BITS_AB-1:0] Bin,
   input signed [BITS_C-1:0] Cin,
   output reg signed [BITS_AB-1:0] Aout,
   output reg signed [BITS_AB-1:0] Bout,
   output reg signed [BITS_C-1:0] Cout
  );
// NOTE: added register enable in v1.1
// Also, Modelsim prefers "reg signed" over "signed reg"

//define internal signals for module
logic signed [BITS_C-1:0] multiply, added, C_reg_mux, C_reg;

//create multiply unit for a and b inputs
assign multiply = Ain * Bin;
//create accumulator for C register
assign added = C_reg + multiply;
//assign C output to value of C Register
assign Cout = C_reg;


always_ff @(posedge clk, negedge rst_n) begin
    //if reset set all registers to 0
    if(!rst_n) begin
        Aout <= '0;
        Bout <= '0;
        C_reg <= '0;
    end
    //if not reset and enable pass values through otherwise keep them the same
    else if (en) begin
        Aout <= Ain;
        Bout <= Bin;
        C_reg <= added;
    end
    else if (WrEn) begin
        C_reg <= Cin;
    end
end

endmodule