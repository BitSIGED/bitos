ENTRY(start)

SECTIONS {
    . = 1M;

    .boot :
    {
        /* force multi bootheader to be first */
        *(.multiboot_header)
    }

    .text :
    {
        *(.text)
    }
}
