
module alu_64(

input [63:0] A,
input [63:0] B,
input [3:0] alu_sel,

output reg [63:0] Y,

output Zero,
output Negative,
output Carry,
output Overflow

);

wire add_en = (alu_sel == 4'b0000);
wire sub_en = (alu_sel == 4'b0001);
wire and_en = (alu_sel == 4'b0010);
wire or_en  = (alu_sel == 4'b0011);
wire xor_en = (alu_sel == 4'b0100);

wire shl_en = (alu_sel == 4'b0101);
wire shr_en = (alu_sel == 4'b0110);
wire asr_en = (alu_sel == 4'b0111);

wire slt_en = (alu_sel == 4'b1000);

wire [63:0] B_mod;
wire Cin;

assign B_mod = sub_en ? ~B : B;
assign Cin   = sub_en ? 1'b1 : 1'b0;

wire [64:0] adder_out;

assign adder_out = {1'b0,A} + {1'b0,B_mod} + Cin;

wire [63:0] add_out =
       (add_en | sub_en) ? adder_out[63:0] : 64'b0;

wire [63:0] logic_out =
       and_en ? (A & B) :
       or_en  ? (A | B) :
       xor_en ? (A ^ B) :
       64'b0;

wire dir;
wire arth_shift;

assign dir = shr_en | asr_en;
assign arth_shift = asr_en;

wire [63:0] shift_out;

barrel_shifter SHIFT1(

.din(A),
.shift(B[5:0]),
.dir(dir),
.arth_shift(arth_shift),
.dout(shift_out)

);

wire [63:0] slt_out;

assign slt_out = slt_en ? (A < B ? 64'd1 : 64'd0) : 64'd0;

always @(*) begin

case(alu_sel)

4'b0000,
4'b0001: Y = add_out;

4'b0010,
4'b0011,
4'b0100: Y = logic_out;

4'b0101,
4'b0110,
4'b0111: Y = shift_out;

4'b1000: Y = slt_out;

default: Y = 64'b0;

endcase

end

assign Zero = ~|Y;

assign Negative = Y[63];

assign Carry =
      (add_en | sub_en) ? adder_out[64] : 1'b0;

assign Overflow =
(add_en) ? ((A[63] & B[63] & ~Y[63]) |
           (~A[63] & ~B[63] & Y[63])) :

(sub_en) ? ((A[63] & ~B[63] & ~Y[63]) |
           (~A[63] & B[63] & Y[63])) :

1'b0;

endmodule

