module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16;
    parameter DATAW=64;
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
  
  typedef enum {READ_C, WRITE_A, WRITE_B, WRITE_C MULTIPLY} state_t;
  logic signed [BITS_AB-1:0] A [DIM-1:0];
  logic signed [BITS_AB-1:0] B [DIM-1:0];
  logic signed [BITS_C-1:0] Cout [DIM-1:0];
  logic [$clog2(DIM)-1:0] Arow, Crow;
  logic en_a, en_b, en_sys, WrEn_a, WrEn_sys;
  state_t state, nxt_state;
  
	memA #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_A(.clk(clk), .rst_n(rst_n), .en(en_sys), .WrEn(WrEn_a), .Ain(dataIn), .Arow(Arow), .Aout(A));
  
	memB #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_B(.clk(clk), .rst_n(rst_n), .en(en_b), .Bin(dataIn), .Bout(B));
  
  systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) SYS_ARR(.clk(clk), .rst_n(rst_n), .WrEn(WrEn_sys), .en(en_sys), .A(A), .B(B), .Cin(dataIn), .Crow(Crow), .Cout(Cout));
  
	assign Arow = addr >> $clog2(BITS_AB);
	assign Crow = addr >> $clog2(BITS_C);
	assign dataOut = (addr[$clog2(BITS_C)-1:0] == 4'd0) ? Cout[DATAW-1:0] : Cout[(DATAW*2)-1:DATAW];
	
  always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= READ_C;
	else
		state <= nxt_state;

always_comb begin
  //en_a = 1'b0;
  en_b = 1'b0;
  en_sys = 1'b0;
  WrEn_a = 1'b0;
  WrEn_sys = 1'b0;
	
	case (state)
		READ_C: begin
			if (addr >= 16'h0100 && addr <= 16'h013f && r_w == 1'b1) begin
				nxt_state = WRITE_A;
				WrEn_a = 1'b1;
			end
			else if (addr >= 16'h0200 && addr <= 16'h023f && r_w == 1'b1) begin
				nxt_state = WRITE_B;
				en_b = 1'b1;
			end
			else if (addr >= 16'h0300 && addr <= 16'h037f && r_w == 1'b1) begin
				nxt_state = WRITE_C;
				WrEn_sys = 1'b1;
			end
			else if (addr == 16'h0400 && r_w == 1'b1) begin
				nxt_state = MULTIPLY;
				en_sys = 1'b1;
			end else nxt_state = READ_C;
		end
		WRITE_A: begin
		end
		WRITE_B: begin
		end
		WRITE_C: begin
		end
		MULTIPLY: begin
		end
		default: nxt_state = READ_C;
	endcase
end
  
  
  
endmodule
  
