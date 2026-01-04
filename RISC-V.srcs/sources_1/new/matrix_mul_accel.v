module matrix_mult_accel (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    output reg  [31:0] rdata
);

    // Accelerator registers (memory-mapped)
    reg [31:0] matrix_a [0:15];  // 4x4 matrix A
    reg [31:0] matrix_b [0:15];  // 4x4 matrix B
    reg [31:0] matrix_c [0:15];  // 4x4 result matrix C
    reg [31:0] control;          // Control register
    reg [31:0] status;           // Status register
    
    integer i, j, k;
    reg computing;
    reg [3:0] compute_state;
    
    // Memory map:
    // 0x10000000-0x1000003C: Matrix A (16 words)
    // 0x10000040-0x1000007C: Matrix B (16 words)
    // 0x10000080-0x100000BC: Matrix C (16 words - read only)
    // 0x100000C0: Control (write 1 to start)
    // 0x100000C4: Status (bit 0: busy, bit 1: done)
    
    wire [7:0] word_addr = addr[7:2];
    
    // Write operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                matrix_a[i] <= 32'h0;
                matrix_b[i] <= 32'h0;
                matrix_c[i] <= 32'h0;
            end
            control <= 32'h0;
            status <= 32'h0;
            computing <= 1'b0;
            compute_state <= 4'h0;
        end else begin
            if (we) begin
                if (word_addr < 16) matrix_a[word_addr] <= wdata;
                else if (word_addr < 32) matrix_b[word_addr - 16] <= wdata;
                else if (word_addr == 48) begin
                    control <= wdata;
                    if (wdata[0]) begin
                        computing <= 1'b1;
                        status <= 32'h1; // Set busy
                        compute_state <= 4'h0;
                    end
                end
            end
            
            // Matrix multiplication state machine
            if (computing) begin
                if (compute_state < 4) begin
                    // Compute row compute_state of result
                    for (j = 0; j < 4; j = j + 1) begin
                        matrix_c[compute_state*4 + j] <= 
                            matrix_a[compute_state*4 + 0] * matrix_b[0*4 + j] +
                            matrix_a[compute_state*4 + 1] * matrix_b[1*4 + j] +
                            matrix_a[compute_state*4 + 2] * matrix_b[2*4 + j] +
                            matrix_a[compute_state*4 + 3] * matrix_b[3*4 + j];
                    end
                    compute_state <= compute_state + 1;
                end else begin
                    computing <= 1'b0;
                    status <= 32'h2; // Set done, clear busy
                    control <= 32'h0;
                end
            end
        end
    end
    
    // Read operations
    always @(*) begin
        if (word_addr < 16) rdata = matrix_a[word_addr];
        else if (word_addr < 32) rdata = matrix_b[word_addr - 16];
        else if (word_addr < 48) rdata = matrix_c[word_addr - 32];
        else if (word_addr == 48) rdata = control;
        else if (word_addr == 49) rdata = status;
        else rdata = 32'h0;
    end

endmodule