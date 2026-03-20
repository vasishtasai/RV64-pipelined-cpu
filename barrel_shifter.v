module barrel_shifter(
    input  [63:0] din,
    input  [5:0]  shift,
    input         dir,
    input         arth_shift,
    output [63:0] dout
);

wire [63:0] s1, s2, s3, s4, s5, s6;
wire [63:0] d1, d2, d3, d4, d5, d6;

wire arith = arth_shift & dir;
wire [63:0] sign_ext = {64{din[63]}};

wire [63:0] l1 = {din[31:0], 32'b0};
wire [63:0] r1 = {(arith ? sign_ext[31:0] : 32'b0), din[63:32]};
mux m1(d1, dir, l1, r1);
mux m2(s1, shift[5], din, d1);

wire [63:0] l2 = {s1[47:0], 16'b0};
wire [63:0] r2 = {(arith ? sign_ext[15:0] : 16'b0), s1[63:16]};
mux m3(d2, dir, l2, r2);
mux m4(s2, shift[4], s1, d2);

wire [63:0] l3 = {s2[55:0], 8'b0};
wire [63:0] r3 = {(arith ? sign_ext[7:0] : 8'b0), s2[63:8]};
mux m5(d3, dir, l3, r3);
mux m6(s3, shift[3], s2, d3);

wire [63:0] l4 = {s3[59:0], 4'b0};
wire [63:0] r4 = {(arith ? sign_ext[3:0] : 4'b0), s3[63:4]};
mux m7(d4, dir, l4, r4);
mux m8(s4, shift[2], s3, d4);

wire [63:0] l5 = {s4[61:0], 2'b0};
wire [63:0] r5 = {(arith ? sign_ext[1:0] : 2'b0), s4[63:2]};
mux m9(d5, dir, l5, r5);
mux m10(s5, shift[1], s4, d5);

wire [63:0] l6 = {s5[62:0], 1'b0};
wire [63:0] r6 = {(arith ? sign_ext[0] : 1'b0), s5[63:1]};
mux m11(d6, dir, l6, r6);
mux m12(s6, shift[0], s5, d6);

assign dout = s6;

endmodule

module mux(
    output [63:0] y,
    input         sel,
    input  [63:0] a,
    input  [63:0] b
);
assign y = sel ? b : a;
endmodule