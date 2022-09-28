module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16,
    parameter DATAW=64
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
  
  typedef enum {READWRITE, WRITE_C, MULTIPLY} state_t;
  logic signed [BITS_AB-1:0] A [DIM-1:0];
  logic signed [BITS_AB-1:0] dataIn_temp [DIM-1:0];
  logic signed [BITS_C-1:0] Cin [(DIM/2)-1:0];
  logic signed [BITS_C-1:0] Cin_first [(DIM/2)-1:0];
  logic signed [BITS_AB-1:0] B [DIM-1:0];
  logic signed [BITS_C-1:0] Cout [DIM-1:0];
  logic [$clog2(DIM)-1:0] Arow, Crow;
  logic [$clog2(DIM*3-2)-1:0] count;
  logic en_b, en_sys, WrEn_a, WrEn_sys, incr_count, rst_count;
  state_t state, nxt_state;


/* ALLISON'S NOTES:
	add to generate loop: save dataIn_temp into Cin_temp in correct form (2 dataIns for 1 Cin)
	add to state machine: in readwrite state, save Cin_temp to register, transfer to write_c state
	in write_c state: set WrEnn_sys
	in systolic array: set Cin to cat (register contents, Cin_temp)
	~only works because we can assume each Cin beginning input will be immediately followed by a Cin ending input~

*/
	
  genvar i;
  generate
	for (i=0; i<DIM; i+=1) begin
		assign dataIn_temp[i] = dataIn[BITS_AB*(i+1)-1:BITS_AB*i];
	end
	for (i=0; i<DIM/2; i+=1) begin
		assign Cin[i] = {dataIn_temp[2*i], dataIn_temp[2*i+1]};
	end

/*
	for(i=0;i<DIM;i++) begin
	     assign Cin[i] = (addr[$clog2(BITS_C)-1:0] == 4'd0 && i < 4) ? dataIn[BITS_C*(i+1)-1:BITS_C*i] :
		(addr[$clog2(BITS_C)-1:0] == 4'd0) ? Cout[i] :
		(addr[$clog2(BITS_C)-1:0] == 4'd8 && i < 4)? Cout[i] : dataIn[BITS_C*(i-3)-1:BITS_C*(i-4)];
	end

	for(i=0;i<DIM;i++) begin
		if(addr[$clog2(BITS_C)-1:0] == 4'd0 && i < 4) begin
			assign Cin[i] = addr[$clog2(BITS_C)-1:0] == 4'd0) ? dataIn[BITS_C*(i+1)-1:BITS_C*i];
		end else if(addr[$clog2(BITS_C)-1:0] == 4'd0) begin
			assign Cin[i] = Cout[i];
		end else if(addr[$clog2(BITS_C)-1:0] == 4'd8 && i < 4) begin
			assign Cin[i] = Cout[i];
		end else begin
			assign Cin[i] = dataIn[BITS_C*(i-3)-1:BITS_C*(i-4)];
		end
	end
*/
  endgenerate



  memA #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_A(.clk(clk), .rst_n(rst_n), .en(en_sys), .WrEn(WrEn_a), .Ain(dataIn_temp), .Arow(Arow), .Aout(A));

  memB #(.BITS_AB(BITS_AB), .DIM(DIM)) MEM_B(.clk(clk), .rst_n(rst_n), .en(en_b), .Bin(dataIn_temp), .Bout(B));
  
  systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) SYS_ARR(.clk(clk), .rst_n(rst_n), .WrEn(WrEn_sys), 
		.en(en_sys), .A(A), .B(B), .Cin({Cin_first,Cin}), .Crow(Crow), .Cout(Cout));
  
  assign Arow = addr >> $clog2(BITS_AB);
  assign Crow = addr >> $clog2(BITS_C);
  assign dataOut = (addr[$clog2(BITS_C)-1:0] == 4'd0) ? {Cout[3], Cout[2], Cout[1], Cout[0]} : {Cout[7], Cout[6], Cout[5], Cout[4]};

//  assign Cin = (addr[$clog2(BITS_C)-1:0] == 4'd0) ? {Cout[7],Cout[6],Cout[5],Cout[4],dataIn} : {dataIn,Cout[3],Cout[2],Cout[1],Cout[0]};

  always_ff @(posedge clk, negedge rst_n)
	  if (!rst_n | rst_count)
		count <= 0;
	else if(incr_count) 
		count <= count +1;

  always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= READWRITE;
	else
		state <= nxt_state;
/*

  always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		for (int i = 0; i<DIM; i+=1) begin
			Cin[i] = 16'd0;
		end
	end
	else if (Cin_first) begin
		j = 0;
		for (int i = 0; i<DIM/2; i+=1) begin
			Cin[i] = {dataIn_temp[j], dataIn_temp[j+1]};
			j+=2;
		end
	end
	else if (Cin_last) begin
		j = 0;
		for (int i = DIM/2; i<DIM; i+=1) begin
			Cin[i] = {dataIn_temp[j], dataIn_temp[j+1]};
			j+=2;
		end
	end
end // don't think this will work but don't wanna delete yet
*/
  always_comb begin
	en_b = 1'b0;
	en_sys = 1'b0;
	WrEn_a = 1'b0;
	WrEn_sys = 1'b0;
	incr_count = 1'b0;
	rst_count = 1'b0;
	Cin_first = Cin_first;
	

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
				nxt_state = WRITE_C;
				Cin_first = Cin;
			end
			else if (addr == 16'h0400 && r_w == 1'b1) begin
				nxt_state = MULTIPLY;
				incr_count = 1'b1;
				en_sys = 1'b1;
			end else nxt_state = READWRITE;
		end
		WRITE_C: begin
			nxt_state = READWRITE;
			WrEn_sys = 1'b1;
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
  
