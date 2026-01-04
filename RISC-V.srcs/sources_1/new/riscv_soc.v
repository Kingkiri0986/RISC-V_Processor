module riscv_soc (
    input  wire clk,
    input  wire rst_n,
    output wire [7:0] debug_pc
);

    wire [31:0] imem_addr, imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire dmem_we, dmem_re;
    wire [31:0] accel_addr, accel_wdata, accel_rdata;
    wire accel_we;
    
    assign debug_pc = imem_addr[9:2];
    
    riscv_core cpu (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .dmem_rdata(dmem_rdata),
        .accel_addr(accel_addr),
        .accel_wdata(accel_wdata),
        .accel_we(accel_we),
        .accel_rdata(accel_rdata)
    );
    
    memory #(
        .ADDR_WIDTH(12),
        .MEM_FILE("program.hex")
    ) imem (
        .clk(clk),
        .addr(imem_addr[13:2]),
        .wdata(32'h0),
        .we(1'b0),
        .re(1'b1),
        .rdata(imem_rdata)
    );
    
    memory #(
        .ADDR_WIDTH(12),
        .MEM_FILE("")
    ) dmem (
        .clk(clk),
        .addr(dmem_addr[13:2]),
        .wdata(dmem_wdata),
        .we(dmem_we),
        .re(dmem_re),
        .rdata(dmem_rdata)
    );
    
    matrix_mult_accel accelerator (
        .clk(clk),
        .rst_n(rst_n),
        .addr(accel_addr),
        .wdata(accel_wdata),
        .we(accel_we),
        .rdata(accel_rdata)
    );

endmodule