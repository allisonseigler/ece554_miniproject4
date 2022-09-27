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
  
  typedef enum {IDLE, READ, WRITE, MULTIPLY} state_t;
  logic en, en_b;
  state_t state, nxt_state;
  
  memA #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_A(.clk(clk), .rst_n(rst_n), .en(en), .WrEn(???), .Ain(???), .Arow(???), .Aout(???));
  
	memB #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_B(.clk(clk), .rst_n(rst_n), .en(en_b), .Bin(???), .Bout(???));
  
  systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) SYS_ARR(.clk(clk), .rst_n(rst_n), .WrEn(???), .en(en), .A(???), .B(???), .Cin(???), .Crow(???), .Cout(???));
  
  
  always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

always_comb begin
  en = 1'b0;
	
	case (state)
		IDLE: begin

		end
		READ: begin
		end
		default: nxt_state = IDLE;
	endcase
end
  
  
  
endmodule
  
