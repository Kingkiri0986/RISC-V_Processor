module memory #(
    parameter ADDR_WIDTH = 14,  // 16KB = 4K words
    parameter DATA_WIDTH = 32,
    parameter MEM_FILE = ""
)(
    input  wire                    clk,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    we,
    input  wire                    re,
    output reg  [DATA_WIDTH-1:0]   rdata
);

    reg [DATA_WIDTH-1:0] mem_array [0:(2**ADDR_WIDTH)-1];
    
    initial begin
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, mem_array);
        end
    end
    
    always @(posedge clk) begin
        if (we) mem_array[addr] <= wdata;
        if (re) rdata <= mem_array[addr];
    end

endmodule