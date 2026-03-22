module alu_64(

input clk,
input rst,

input valid_in,

input [63:0] A,
input [63:0] B,
input [3:0] alu_sel,

output reg valid_out,

output reg [63:0] Y,
output reg Zero,
output reg Negative,
output reg Carry,
output reg Overflow

);

reg [63:0] A_s1, B_s1;
reg [3:0] sel_s1;
reg valid_s1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        A_s1 <= 0;
        B_s1 <= 0;
        sel_s1 <= 0;
        valid_s1 <= 0;
    end else begin
        A_s1 <= A;
        B_s1 <= B;
        sel_s1 <= alu_sel;
        valid_s1 <= valid_in;
    end
end

wire add_en = (sel_s1 == 4'b0000);
wire sub_en = (sel_s1 == 4'b0001);
wire and_en = (sel_s1 == 4'b0010);
wire or_en  = (sel_s1 == 4'b0011);
wire xor_en = (sel_s1 == 4'b0100);

wire shl_en = (sel_s1 == 4'b0101);
wire shr_en = (sel_s1 == 4'b0110);
wire asr_en = (sel_s1 == 4'b0111);

wire slt_en = (sel_s1 == 4'b1000);

wire [63:0] B_mod = sub_en ? ~B_s1 : B_s1;
wire Cin = sub_en ? 1'b1 : 1'b0;

wire [64:0] adder_out = {1'b0,A_s1} + {1'b0,B_mod} + Cin;
wire [63:0] add_out = adder_out[63:0];

wire [63:0] logic_out =
       and_en ? (A_s1 & B_s1) :
       or_en  ? (A_s1 | B_s1) :
       xor_en ? (A_s1 ^ B_s1) :
       64'b0;

wire dir = shr_en | asr_en;
wire arth_shift = asr_en;

wire [63:0] shift_out;

barrel_shifter SHIFT1(
    .din(A_s1),
    .shift(B_s1[5:0]),
    .dir(dir),
    .arth_shift(arth_shift),
    .dout(shift_out)
);

wire [63:0] slt_out = (A_s1 < B_s1) ? 64'd1 : 64'd0;

reg [63:0] add_r, logic_r, shift_r, slt_r;
reg [64:0] adder_out_r;

reg add_en_r, sub_en_r, and_en_r, or_en_r, xor_en_r;
reg shl_en_r, shr_en_r, asr_en_r, slt_en_r;
reg valid_s2;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        add_r <= 0; logic_r <= 0; shift_r <= 0; slt_r <= 0;
        adder_out_r <= 0;
        add_en_r <= 0; sub_en_r <= 0;
        and_en_r <= 0; or_en_r <= 0; xor_en_r <= 0;
        shl_en_r <= 0; shr_en_r <= 0; asr_en_r <= 0;
        slt_en_r <= 0;
        valid_s2 <= 0;
    end else begin
        add_r <= add_out;
        logic_r <= logic_out;
        shift_r <= shift_out;
        slt_r <= slt_out;
        adder_out_r <= adder_out;
        add_en_r <= add_en;
        sub_en_r <= sub_en;
        and_en_r <= and_en;
        or_en_r <= or_en;
        xor_en_r <= xor_en;
        shl_en_r <= shl_en;
        shr_en_r <= shr_en;
        asr_en_r <= asr_en;
        slt_en_r <= slt_en;
        valid_s2 <= valid_s1;
    end
end

reg [63:0] Y_exec;
reg valid_s3;

always @(*) begin
    if (add_en_r | sub_en_r)
        Y_exec = add_r;
    else if (and_en_r | or_en_r | xor_en_r)
        Y_exec = logic_r;
    else if (shl_en_r | shr_en_r | asr_en_r)
        Y_exec = shift_r;
    else if (slt_en_r)
        Y_exec = slt_r;
    else
        Y_exec = 64'b0;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        valid_s3 <= 0;
    else
        valid_s3 <= valid_s2;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        Y <= 0;
        Zero <= 0;
        Negative <= 0;
        Carry <= 0;
        Overflow <= 0;
        valid_out <= 0;
    end else begin
        Y <= Y_exec;
        Zero <= ~|Y_exec;
        Negative <= Y_exec[63];
        Carry <= (add_en_r | sub_en_r) ? adder_out_r[64] : 1'b0;
        Overflow <=
        (add_en_r) ? ((A_s1[63] & B_s1[63] & ~Y_exec[63]) |
                     (~A_s1[63] & ~B_s1[63] & Y_exec[63])) :
        (sub_en_r) ? ((A_s1[63] & ~B_s1[63] & ~Y_exec[63]) |
                     (~A_s1[63] & B_s1[63] & Y_exec[63])) :
        1'b0;
        valid_out <= valid_s3;
    end
end

endmodule