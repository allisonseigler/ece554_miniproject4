<<<<<<< HEAD
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
  logic enA;
  logic enB;
  logic enS;
  logic WrEnA;
  logic WrEnS;

  state_t state, next_state;
  
  memA #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_A(.clk(clk), .rst_n(rst_n), .en(enA), .WrEn(WrEnA), .Ain(dataIn), .Arow(???), .Aout(???));
  
  memB #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_B(.clk(clk), .rst_n(rst_n), .en(enB), .Bin(dataIn), .Bout(???));
  
  systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) SYS_ARR(.clk(clk), .rst_n(rst_n), .WrEn(WrEnS), .en(enS), .A(???), .B(???), .Cin(???), .Crow(???), .Cout(???));
  
  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
       state <= IDLE;
    else
       state <= nxt_state;

  always_comb begin
     enA = 1'b0;	
     WrEnA = 1'b0;
     enB = 1'b0;
     enS = 1'b0;
     WrEnS = 1'b0;

     case (state)
	IDLE: begin
           
	end
	READ: begin
	end
	default: nxt_state = IDLE;
     endcase
  end
  
  
  
endmodule
endmodule
=======
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
  
  typedef enum {READWRITE, MULTIPLY} state_t;
  logic signed [BITS_AB-1:0] A [DIM-1:0];
  logic signed [BITS_AB-1:0] B [DIM-1:0];
  logic signed [BITS_C-1:0] Cout [DIM-1:0];
  logic [$clog2(DIM)-1:0] Arow, Crow;
  logic [$clog2(DIM*3-2)-1:0] count;
  logic en_b, en_sys, WrEn_a, WrEn_sys, incr_count, rst_count;
  state_t state, nxt_state;
  
  memA #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_A(.clk(clk), .rst_n(rst_n), .en(en_sys), .WrEn(WrEn_a), .Ain(dataIn), .Arow(Arow), .Aout(A));

  memB #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_B(.clk(clk), .rst_n(rst_n), .en(en_b), .Bin(dataIn), .Bout(B));
  
  systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) SYS_ARR(.clk(clk), .rst_n(rst_n), .WrEn(WrEn_sys), 
		.en(en_sys), .A(A), .B(B), .Cin(dataIn), .Crow(Crow), .Cout(Cout));
  
  assign Arow = addr >> $clog2(BITS_AB);
  assign Crow = addr >> $clog2(BITS_C);
  assign dataOut = (addr[$clog2(BITS_C)-1:0] == 4'd0) ? Cout[DATAW-1:0] : Cout[(DATAW*2)-1:DATAW];
	
  always_ff @(posedge clk, negedge rst_n)
	  if (!rst_n | rst_count)
		count <= 0;
	else if(incr_count) 
		count <= count +1;

  always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= READ_C;
	else
		state <= nxt_state;

  always_comb begin
	en_b = 1'b0;
	en_sys = 1'b0;
	WrEn_a = 1'b0;
	WrEn_sys = 1'b0;
	incr_count = 1'b0;
	rst_count = 1'b0;
	
	case (state)
		READWRITE: begin
			if (addr >= 16'h0100 && addr <= 16'h013f && r_w == 1'b1) begin
				nxt_state = READWRITE;
				WrEn_a = 1'b1;
			end
			else if (addr >= 16'h0200 && addr <= 16'h023f && r_w == 1'b1) begin
				nxt_state = READWRITE;
				en_b = 1'b1;
			end
			else if (addr >= 16'h0300 && addr <= 16'h037f && r_w == 1'b1) begin
				nxt_state = READWRITE;
				WrEn_sys = 1'b1;
			end
			else if (addr == 16'h0400 && r_w == 1'b1) begin
				nxt_state = MULTIPLY;
				incr_count = 1'b1;
				en_sys = 1'b1;
			end else nxt_state = READWRITE;
		end

		MULTIPLY: begin
			if (count == DIM*3-2) begin
				nxt_state = READWRITE;
				rst_count = 1'b1;
			end else begin
				nxt_state = MULTIPLY;
				en_sys = 1'b1;
				incr_count = 1'b1;
			end		
		end
		default: nxt_state = READWRITE;
	endcase
end
  
  
  
endmodule
  
>>>>>>> ca15907733179b7edb82291386a6e68ffe453c70
