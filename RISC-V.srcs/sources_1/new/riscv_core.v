module riscv_core (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] accel_addr,
    output wire [31:0] accel_wdata,
    output wire        accel_we,
    input  wire [31:0] accel_rdata
);

    // Program Counter
    reg [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc + 4;
    wire pc_sel;
    wire [31:0] pc_branch;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc <= 32'h0;
        else pc <= pc_next;
    end
    
    assign imem_addr = pc;
    assign pc_next = pc_sel ? pc_branch : pc_plus4;
    
    // IF/ID Pipeline Register
    reg [31:0] if_id_instr, if_id_pc;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_instr <= 32'h0;
            if_id_pc <= 32'h0;
        end else begin
            if_id_instr <= imem_rdata;
            if_id_pc <= pc;
        end
    end
    
    // Decode
    wire [6:0] opcode = if_id_instr[6:0];
    wire [4:0] rd = if_id_instr[11:7];
    wire [2:0] funct3 = if_id_instr[14:12];
    wire [4:0] rs1 = if_id_instr[19:15];
    wire [4:0] rs2 = if_id_instr[24:20];
    wire [6:0] funct7 = if_id_instr[31:25];
    
    // Register File (32 registers)
    reg [31:0] registers [0:31];
    integer i;
    
    wire [31:0] rs1_data = (rs1 == 0) ? 32'h0 : registers[rs1];
    wire [31:0] rs2_data = (rs2 == 0) ? 32'h0 : registers[rs2];
    
    // Immediate Generation
    wire [31:0] imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    wire [31:0] imm_s = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    wire [31:0] imm_b = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0};
    wire [31:0] imm_u = {if_id_instr[31:12], 12'h0};
    wire [31:0] imm_j = {{11{if_id_instr[31]}}, if_id_instr[31], if_id_instr[19:12], if_id_instr[20], if_id_instr[30:21], 1'b0};
    
    // ID/EX Pipeline Register
    reg [31:0] id_ex_rs1_data, id_ex_rs2_data, id_ex_imm, id_ex_pc;
    reg [4:0] id_ex_rd;
    reg [6:0] id_ex_opcode;
    reg [2:0] id_ex_funct3;
    reg [6:0] id_ex_funct7;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_rs1_data <= 32'h0;
            id_ex_rs2_data <= 32'h0;
            id_ex_imm <= 32'h0;
            id_ex_pc <= 32'h0;
            id_ex_rd <= 5'h0;
            id_ex_opcode <= 7'h0;
            id_ex_funct3 <= 3'h0;
            id_ex_funct7 <= 7'h0;
        end else begin
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_rd <= rd;
            id_ex_opcode <= opcode;
            id_ex_funct3 <= funct3;
            id_ex_funct7 <= funct7;
            id_ex_pc <= if_id_pc;
            
            case (opcode)
                7'b0010011, 7'b0000011, 7'b1100111: id_ex_imm <= imm_i;
                7'b0100011: id_ex_imm <= imm_s;
                7'b1100011: id_ex_imm <= imm_b;
                7'b0110111, 7'b0010111: id_ex_imm <= imm_u;
                7'b1101111: id_ex_imm <= imm_j;
                default: id_ex_imm <= 32'h0;
            endcase
        end
    end
    
    // Execute: ALU
    reg [31:0] alu_result;
    reg alu_zero;
    wire [31:0] alu_a = id_ex_rs1_data;
    wire [31:0] alu_b = (id_ex_opcode == 7'b0110011) ? id_ex_rs2_data : id_ex_imm;
    
    always @(*) begin
        case (id_ex_opcode)
            7'b0110011, 7'b0010011: begin // R-type and I-type
                case (id_ex_funct3)
                    3'b000: alu_result = (id_ex_opcode == 7'b0110011 && id_ex_funct7[5]) ? 
                                         alu_a - alu_b : alu_a + alu_b;
                    3'b001: alu_result = alu_a << alu_b[4:0];
                    3'b010: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'h1 : 32'h0;
                    3'b011: alu_result = (alu_a < alu_b) ? 32'h1 : 32'h0;
                    3'b100: alu_result = alu_a ^ alu_b;
                    3'b101: alu_result = id_ex_funct7[5] ? 
                                         $signed(alu_a) >>> alu_b[4:0] : alu_a >> alu_b[4:0];
                    3'b110: alu_result = alu_a | alu_b;
                    3'b111: alu_result = alu_a & alu_b;
                    default: alu_result = 32'h0;
                endcase
            end
            7'b0000011, 7'b0100011: alu_result = alu_a + alu_b; // Load/Store
            7'b1100011: begin // Branch
                case (id_ex_funct3)
                    3'b000: alu_zero = (alu_a == alu_b);  // BEQ
                    3'b001: alu_zero = (alu_a != alu_b);  // BNE
                    3'b100: alu_zero = ($signed(alu_a) < $signed(alu_b));  // BLT
                    3'b101: alu_zero = ($signed(alu_a) >= $signed(alu_b)); // BGE
                    3'b110: alu_zero = (alu_a < alu_b);   // BLTU
                    3'b111: alu_zero = (alu_a >= alu_b);  // BGEU
                    default: alu_zero = 1'b0;
                endcase
                alu_result = alu_a + alu_b;
            end
            7'b0110111: alu_result = id_ex_imm; // LUI
            7'b0010111: alu_result = id_ex_pc + id_ex_imm; // AUIPC
            7'b1101111, 7'b1100111: alu_result = id_ex_pc + 4; // JAL/JALR
            default: alu_result = 32'h0;
        endcase
    end
    
    assign pc_branch = id_ex_pc + id_ex_imm;
    assign pc_sel = (id_ex_opcode == 7'b1100011 && alu_zero) || 
                    (id_ex_opcode == 7'b1101111) ||
                    (id_ex_opcode == 7'b1100111);
    
    // EX/MEM Pipeline Register
    reg [31:0] ex_mem_alu_result, ex_mem_rs2_data;
    reg [4:0] ex_mem_rd;
    reg [6:0] ex_mem_opcode;
    reg [2:0] ex_mem_funct3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result <= 32'h0;
            ex_mem_rs2_data <= 32'h0;
            ex_mem_rd <= 5'h0;
            ex_mem_opcode <= 7'h0;
            ex_mem_funct3 <= 3'h0;
        end else begin
            ex_mem_alu_result <= alu_result;
            ex_mem_rs2_data <= id_ex_rs2_data;
            ex_mem_rd <= id_ex_rd;
            ex_mem_opcode <= id_ex_opcode;
            ex_mem_funct3 <= id_ex_funct3;
        end
    end
    
    // Memory Access
    wire is_accel_addr = (ex_mem_alu_result >= 32'h10000000);
    
    assign dmem_addr = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_rs2_data;
    assign dmem_we = (ex_mem_opcode == 7'b0100011) && !is_accel_addr;
    assign dmem_re = (ex_mem_opcode == 7'b0000011) && !is_accel_addr;
    
    assign accel_addr = ex_mem_alu_result;
    assign accel_wdata = ex_mem_rs2_data;
    assign accel_we = (ex_mem_opcode == 7'b0100011) && is_accel_addr;
    
    wire [31:0] mem_rdata = is_accel_addr ? accel_rdata : dmem_rdata;
    
    // MEM/WB Pipeline Register
    reg [31:0] mem_wb_alu_result, mem_wb_mem_data;
    reg [4:0] mem_wb_rd;
    reg [6:0] mem_wb_opcode;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_alu_result <= 32'h0;
            mem_wb_mem_data <= 32'h0;
            mem_wb_rd <= 5'h0;
            mem_wb_opcode <= 7'h0;
        end else begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_data <= mem_rdata;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_opcode <= ex_mem_opcode;
        end
    end
    
    // Write Back
    wire [31:0] wb_data = (mem_wb_opcode == 7'b0000011) ? mem_wb_mem_data : mem_wb_alu_result;
    wire wb_enable = (mem_wb_rd != 0) && 
                     (mem_wb_opcode == 7'b0110011 || mem_wb_opcode == 7'b0010011 ||
                      mem_wb_opcode == 7'b0000011 || mem_wb_opcode == 7'b0110111 ||
                      mem_wb_opcode == 7'b0010111 || mem_wb_opcode == 7'b1101111 ||
                      mem_wb_opcode == 7'b1100111);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) registers[i] <= 32'h0;
        end else if (wb_enable) begin
            registers[mem_wb_rd] <= wb_data;
        end
    end

endmodule