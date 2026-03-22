module tb_alu_64;

reg clk;
reg rst;
reg valid_in;

reg [63:0] A, B;
reg [3:0] alu_sel;

wire [63:0] Y;
wire Zero, Negative, Carry, Overflow;
wire valid_out;

alu_64 dut(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .A(A),
    .B(B),
    .alu_sel(alu_sel),
    .valid_out(valid_out),
    .Y(Y),
    .Zero(Zero),
    .Negative(Negative),
    .Carry(Carry),
    .Overflow(Overflow)
);

always #5 clk = ~clk;

initial begin
    $display("Time\tvalid_in\tA\tB\tSEL\tvalid_out\tY\tZ\tN\tC\tV");
    $monitor("%0t\t%b\t%d\t%d\t%b\t%b\t%d\t%b\t%b\t%b\t%b",
             $time, valid_in, A, B, alu_sel,
             valid_out, Y, Zero, Negative, Carry, Overflow);
end

initial begin
    clk = 0;
    rst = 1;
    valid_in = 0;
    A = 0;
    B = 0;
    alu_sel = 0;

    #10 rst = 0;

    // -------- TEST CASES --------

    @(posedge clk);
    valid_in = 1; A = 10; B = 5; alu_sel = 4'b0000; // ADD

    @(posedge clk);
    A = 10; B = 5; alu_sel = 4'b0001; // SUB

    @(posedge clk);
    A = 12; B = 10; alu_sel = 4'b0010; // AND

    @(posedge clk);
    A = 12; B = 10; alu_sel = 4'b0011; // OR

    @(posedge clk);
    A = 12; B = 10; alu_sel = 4'b0100; // XOR

    @(posedge clk);
    A = 4; B = 1; alu_sel = 4'b0101; // SHL

    @(posedge clk);
    A = 16; B = 2; alu_sel = 4'b0110; // SHR

    @(posedge clk);
    A = -8; B = 1; alu_sel = 4'b0111; // ASR

    @(posedge clk);
    A = 3; B = 5; alu_sel = 4'b1000; // SLT

    // stop input
    @(posedge clk);
    valid_in = 0;

    // wait for pipeline flush
    repeat(10) @(posedge clk);

    $finish;
end

endmodule