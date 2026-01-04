OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 16K
    RAM (rw) : ORIGIN = 0x00004000, LENGTH = 16K
}

SECTIONS {
    .text : { *(.text*) } > ROM
    .data : { *(.data*) } > RAM
    .bss : { *(.bss*) } > RAM
}