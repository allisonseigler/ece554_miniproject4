module systolic_array
#(
   parameter BITS_AB=8,
   parameter BITS_C=16,
   parameter DIM=8
)
(
   input clk,rst_n,WrEn,en,
   input signed [BITS_AB-1:0] A [DIM-1:0],
   input signed [BITS_AB-1:0] B [DIM-1:0],
   input signed [BITS_C-1:0]  Cin [DIM-1:0],
   input [$clog2(DIM)-1:0]    Crow,
   output signed [BITS_C-1:0] Cout [DIM-1:0]
);

   genvar row, col;

   logic signed [BITS_AB-1:0] Aval [DIM:0][DIM:0];
   logic signed [BITS_AB-1:0] Bval [DIM:0][DIM:0];
   logic signed [BITS_C-1: 0] Cval [DIM-1:0][DIM-1:0];
  
   generate 
      for(row = 0 ; row < DIM; row++) begin
          assign Aval[row][0] = A[row];
      end
      
      for(col = 0; col < DIM; col++) begin
          assign Bval[0][col] = B[col];
      end

      for (row = 0; row < DIM; row++) begin
         for (col = 0; col < DIM; col++) begin
	     tpumac tpu(.clk(clk), 
			.rst_n(rst_n), 
			.WrEn(WrEn && (row == Crow)), 
			.en(en),
                 	.Ain(Aval[row][col]), 
			.Bin(Bval[row][col]), 
			.Cin(Cin[col]),
                 
			.Aout(Aval[row][col+1]), 
			.Bout(Bval[row+1][col]), 
			.Cout(Cval[row][col]));
         end
      end
   endgenerate

   assign Cout = Cval[Crow];
endmodule
   
