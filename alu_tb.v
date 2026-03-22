
`timescale 1ns/1ps

module alu_tb;

reg [63:0] A;
reg [63:0] B;
reg [3:0] alu_sel;

wire [63:0] Y;
wire Zero;
wire Negative;
wire Carry;
wire Overflow;

alu_64 DUT(
.A(A),
.B(B),
.alu_sel(alu_sel),
.Y(Y),
.Zero(Zero),
.Negative(Negative),
.Carry(Carry),
.Overflow(Overflow)
);

initial begin

$display("time\tA\tB\tALU\tY\tZ\tN\tC\tV");
$monitor("%0t\t%d\t%d\t%b\t%d\t%b\t%b\t%b\t%b",
$time,A,B,alu_sel,Y,Zero,Negative,Carry,Overflow);

A=15; B=10; alu_sel=4'b0000; #10;
A=20; B=5;  alu_sel=4'b0001; #10;

A=64'hF0F0; B=64'h0FF0; alu_sel=4'b0010; #10;
A=64'hF0F0; B=64'h0FF0; alu_sel=4'b0011; #10;
A=64'hAAAA; B=64'h5555; alu_sel=4'b0100; #10;

A=64'h1;  B=2; alu_sel=4'b0101; #10;
A=64'h10; B=2; alu_sel=4'b0110; #10;
A=-64'd16; B=2; alu_sel=4'b0111; #10;

A=5; B=10; alu_sel=4'b1000; #10;

A=5; B=5; alu_sel=4'b0001; #10;
A=5; B=10; alu_sel=4'b0001; #10;

A=64'h7FFFFFFFFFFFFFFF; B=1; alu_sel=4'b0000; #10;

$finish;

end

endmodule

