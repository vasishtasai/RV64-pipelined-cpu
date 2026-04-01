//instrucrions used 
//R-type---ADD,SUB,AND,OR,XOR,SLT,SLL,SRL,SRA
//I-type---ADDI,LD,JALR
//S-type---SD
//B-type---BEQ
//J-type---JAL


// ===================== PC =====================
module pc(input clk, input rst, input [63:0] pc_next, output reg [63:0] pc);
always @(posedge clk or posedge rst)
    if (rst) pc <= 0;
    else pc <= pc_next;
endmodule


// ===================== INSTRUCTION MEMORY =====================
module imem(input [63:0] addr, output [31:0] inst);

reg [31:0] mem [0:255];

initial begin

mem[0]  = 32'h00500093; // ADDI x1, x0, 5
mem[1]  = 32'h00A00113; // ADDI x2, x0, 10


mem[2]  = 32'h002081B3; // ADD  x3, x1, x2  → 15
mem[3]  = 32'h40208233; // SUB  x4, x1, x2  → -5


mem[4]  = 32'h0020F2B3; // AND
mem[5]  = 32'h0020E333; // OR
mem[6]  = 32'h0020C3B3; // XOR


mem[7]  = 32'h0020A433; // SLT (5 < 10 → 1)


mem[8]  = 32'h002094B3; // SLL
mem[9]  = 32'h0020D533; // SRL
mem[10] = 32'h4020D5B3; // SRA


mem[11] = 32'h40100293; // ADDI x5, x0, -31 (negative test)


mem[12] = 32'h00303023; // SD x3, 0(x0)
mem[13] = 32'h00003103; // LD x2, 0(x0)


mem[14] = 32'h00208663; // BEQ x1,x2 (false case)


mem[15] = 32'h00500113; // ADDI x2,x0,5


mem[16] = 32'h00208663; // BEQ x1,x2 → should branch


mem[17] = 32'h00110193; // ADDI x3,x2,1

mem[18] = 32'h008000EF; // JAL x1, +8  (jump to mem[20], x1 = return addr)

mem[19] = 32'hFFF00293; // ADDI x5, x0, -1 (should be skipped if JAL works)

mem[20] = 32'h00100313; // ADDI x6, x0, 1  (executed after jump)

// Now test JALR (return using x1)
mem[21] = 32'h00008067; // JALR x0, x1, 0  (return to mem[19])

// After return, this should execute:
mem[22] = 32'h00200393; // ADDI x7, x0, 2
end

assign inst = mem[addr[9:2]];
endmodule


// ===================== REGISTER FILE =====================
module reg_file(
    input clk,
    input [4:0] rs1, rs2, rd,
    input [63:0] write_data,
    input reg_write,
    output [63:0] rd1, rd2
);

reg [63:0] regs [0:31];
integer i;//initializing memory locations as 0
initial begin
    for (i = 0; i < 32; i = i + 1)
        regs[i] = 64'd0;
end

assign rd1 = (rs1==0)?0:regs[rs1];
assign rd2 = (rs2==0)?0:regs[rs2];

always @(posedge clk)
    if (reg_write && rd!=0)
        regs[rd] <= write_data;

endmodule


// ===================== CONTROL UNIT =====================
module control_unit(
    input [6:0] opcode,
    output reg reg_write, alu_src, mem_read, mem_write, branch,jump,jalr,
    output reg [1:0] alu_op,immsrc,result_src
);

always @(*) begin
    
    reg_write = 0;
    alu_src   = 0;
    mem_read  = 0;
    mem_write = 0;
    result_src= 0;
    branch    = 0;
    jump = 0;
    jalr = 0;
    alu_op    = 2'b00;
    immsrc    = 2'b00;   

    case(opcode)

    7'b0110011: begin // R-type
        reg_write=1;
        alu_src=0;
        alu_op=2'b10;
        immsrc=2'b00; // don't care,but keeping x is not recomendable so changed x to 0.
    end

    7'b0010011: begin // I-type (ADDI)
        reg_write=1;
        alu_src=1;
        alu_op=2'b00;
        immsrc=2'b00;
    end

    7'b0000011: begin // LOAD
        reg_write=1;
        alu_src=1;
        mem_read=1;
        result_src=2'b01;
        alu_op=2'b00;
        immsrc=2'b00;
    end

    7'b0100011: begin // STORE
        alu_src=1;
        mem_write=1;
        alu_op=2'b00;
        immsrc=2'b01;
    end

    7'b1100011: begin // BRANCH
        branch=1;
        alu_src=0;
        alu_op=2'b01;
        immsrc=2'b10;
    end
    
    
    7'b1101111: begin // JAL
    reg_write = 1;
    jump      = 1;
    immsrc    = 2'b11;
    result_src = 2'b10;
end
    7'b1100111: begin // JALR
    reg_write = 1;
    jalr      = 1;
    alu_src   = 1;
    immsrc    = 2'b00;   // I-type
    result_src= 2'b10;   // PC+4
end

    endcase
end
endmodule


// ===================== ALU CONTROL =====================
module alu_control(
    input [1:0] alu_op,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_sel
);

always @(*) begin
    case(alu_op)

    2'b00: alu_sel = 4'b0000;
    2'b01: alu_sel = 4'b0001;

    2'b10: begin
        case({funct7,funct3})
        10'b0000000000: alu_sel=4'b0000;
        10'b0100000000: alu_sel=4'b0001;
        10'b0000000111: alu_sel=4'b0010;
        10'b0000000110: alu_sel=4'b0011;
        10'b0000000100: alu_sel=4'b0100;
        10'b0000000001: alu_sel=4'b0101;
        10'b0000000101: alu_sel=4'b0110;
        10'b0100000101: alu_sel=4'b0111;
        10'b0000000010: alu_sel=4'b1000;
        default: alu_sel=4'b0000;
        endcase
    end

    default: alu_sel=4'b0000;
    endcase
end
endmodule


// ===================== IMMEDIATE GENERATOR =====================
module imm_gen(
    input [31:0] inst,
    input [1:0] immsrc,
    output reg [63:0] imm
);

always @(*) begin
    case(immsrc)

    2'b00: // I-type (ADDI, LOAD)
        imm = {{52{inst[31]}}, inst[31:20]};

    2'b01: // S-type (STORE)
        imm = {{52{inst[31]}}, inst[31:25], inst[11:7]};

    2'b10: // B-type (BRANCH)
        imm = {{51{inst[31]}}, inst[31], inst[7],
               inst[30:25], inst[11:8], 1'b0};
    2'b11: // J-type (JAL)
    imm = {{43{inst[31]}}, inst[31],
           inst[19:12],
           inst[20],
           inst[30:21],
           1'b0};           

    default:
        imm = 64'b0;

    endcase
end
endmodule


// ===================== DATA MEMORY =====================


module dmem(
    input clk,
    input mem_read, mem_write,
    input [7:0] addr,
    input [63:0] write_data,
    output reg [63:0] read_data
);

reg [63:0] mem [0:255];

integer i;
initial begin
    for (i = 0; i < 256; i = i + 1)
        mem[i] = 64'd0;
end

always @(posedge clk) begin//      first ued read as combinational later upgraded into sequential
    if (mem_write)
        mem[addr] <= write_data;

    if (mem_read)
        read_data <= mem[addr];//    change ofaddr[10:3] to addr is done to reduce no of unused ports
    else
        read_data <= 64'd0;
end


endmodule




// ===================== TOP MODULE =====================
module RV64_singlecycle(input clk, input rst);

wire [63:0] pc, pc_next;
wire [31:0] inst;

wire [4:0] rs1, rs2, rd;
wire [63:0] rd1, rd2, imm;

wire reg_write, alu_src, mem_read, mem_write,  branch;
wire [1:0] alu_op,result_src;
wire [3:0] alu_sel;

wire [63:0] alu_result, mem_data, write_data, alu_B;
wire zero, negative, carry, overflow,jump,jalr;
wire [1:0] immsrc;

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd  = inst[11:7];

pc PC(clk,rst,pc_next,pc);
imem IMEM(pc,inst);

control_unit CU(
    .opcode(inst[6:0]),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .alu_op(alu_op),
    .immsrc(immsrc),
    .result_src(result_src)
);
reg_file RF(clk,rs1,rs2,rd,write_data,reg_write,rd1,rd2);

imm_gen IMM(inst,immsrc,imm);

alu_control ALUCTRL(alu_op,inst[14:12],inst[31:25],alu_sel);

assign alu_B = alu_src ? imm : rd2;

alu_64 ALU(
    .A(rd1),
    .B(alu_B),
    .alu_sel(alu_sel),
    .Y(alu_result),
    .Zero(zero),
    .Negative(negative),
    .Carry(carry),
    .Overflow(overflow)
);

dmem DMEM(clk,mem_read,mem_write,alu_result[10:3],rd2,mem_data);//replaced alu_result[10:3] with alu_result 

wire pcsrc;
wire [63:0] pc_plus4, pc_target,jalr_target;

assign pc_plus4  = pc + 4;
assign pc_target = pc + imm;
assign jalr_target = (rd1 + imm) & ~64'd1;

assign pcsrc = (branch && zero) || jump;//usage of logical operators instead of bitwise operators

assign pc_next =
    jalr        ? jalr_target :
    pcsrc       ? pc_target  :
                  pc_plus4;

assign write_data =
    (result_src == 2'b00) ? alu_result :
    (result_src == 2'b01) ? mem_data   :
    (result_src == 2'b10) ? pc_plus4   :
                           64'd0;  


                                                   


endmodule