`timescale 1ns/1ps

module tb_riscv_soc;

    reg clk, rst_n;
    wire [7:0] debug_pc;
    
    riscv_soc dut (
        .clk(clk),
        .rst_n(rst_n),
        .debug_pc(debug_pc)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    initial begin
        rst_n = 0;
        #20 rst_n = 1;
        
        #10000;
        
        $display("Simulation Complete");
        $finish;
    end
    
    initial begin
        $dumpfile("riscv_soc.vcd");
        $dumpvars(0, tb_riscv_soc);
    end

endmodule