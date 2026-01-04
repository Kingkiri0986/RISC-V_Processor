#define ACCEL_BASE 0x10000000
#define MATRIX_A   (ACCEL_BASE + 0x00)
#define MATRIX_B   (ACCEL_BASE + 0x40)
#define MATRIX_C   (ACCEL_BASE + 0x80)
#define CONTROL    (ACCEL_BASE + 0xC0)
#define STATUS     (ACCEL_BASE + 0xC4)

volatile int* matrix_a = (int*)MATRIX_A;
volatile int* matrix_b = (int*)MATRIX_B;
volatile int* matrix_c = (int*)MATRIX_C;
volatile int* control = (int*)CONTROL;
volatile int* status = (int*)STATUS;

void matrix_multiply() {
    // Load matrix A
    matrix_a[0] = 1; matrix_a[1] = 2; matrix_a[2] = 3; matrix_a[3] = 4;
    matrix_a[4] = 5; matrix_a[5] = 6; matrix_a[6] = 7; matrix_a[7] = 8;
    matrix_a[8] = 9; matrix_a[9] = 10; matrix_a[10] = 11; matrix_a[11] = 12;
    matrix_a[12] = 13; matrix_a[13] = 14; matrix_a[14] = 15; matrix_a[15] = 16;
    
    // Load matrix B (identity for testing)
    matrix_b[0] = 1; matrix_b[1] = 0; matrix_b[2] = 0; matrix_b[3] = 0;
    matrix_b[4] = 0; matrix_b[5] = 1; matrix_b[6] = 0; matrix_b[7] = 0;
    matrix_b[8] = 0; matrix_b[9] = 0; matrix_b[10] = 1; matrix_b[11] = 0;
    matrix_b[12] = 0; matrix_b[13] = 0; matrix_b[14] = 0; matrix_b[15] = 1;
    
    // Start computation
    *control = 1;
    
    // Wait for completion
    while ((*status & 0x2) == 0);
    
    // Result now in matrix_c
}

int main() {
    matrix_multiply();
    while(1); // Infinite loop
    return 0;
}