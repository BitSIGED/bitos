global start
extern long_mode_start

P1_COUNT equ 4

section .text
bits 32
start:
    ; Setup tempory stack
    mov esp, boot_stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call set_up_page_tables
    call enable_paging

    lgdt [gdt64.pointer]
    jmp gdt64.code:long_mode_start
         
    mov al, "L"
    jmp error

set_up_page_tables: 
  ; map first P4 entry to P3 table 
  mov eax, p3_table
  or eax, 0b11 ; present + writable 
  mov [p4_table], eax
  ; map P3 to P2
  mov eax, p2_table
  or eax, 0b11
  mov [p3_table], eax

  mov ecx, 0
.map_p2:
  mov eax, ecx 
  shl eax, 12 ; ecx * 4096 aka side of one P1 table 
  add eax, p1_tables
  or eax, 0b11 ; present and writable
  mov [p2_table + ecx * 8], eax 
  inc ecx 
  cmp ecx, P1_COUNT
  jne .map_p2

  mov ecx, 1 ; leave null page unmapped to prevent null pointer ref
.map_p1:
  mov eax, ecx
  shl eax, 12
  or eax, 0b11 
  mov [p1_tables + ecx * 8], eax 
  inc ecx
  cmp ecx, P1_COUNT * 512 
  jne .map_p1
  ret 


enable_paging:
  mov eax, p4_table ; laod P4 into cr3
  mov cr3, eax 
  
  mov eax, cr4 ; enable PAE flag physical address extention
  or eax, 1 << 5 
  mov cr4, eax 

  mov ecx, 0xC0000080 ; set long mode EFER MSR 
  rdmsr 
  or eax, 1 << 8 
  wrmsr
  
  mov eax, cr0 ; enable paging in the cr0 
  or eax, 1 << 31 
  mov cr0, eax 
  
  ret 

check_multiboot:
  cmp eax, 0x36d76289 ; multiboot
  jne .no_multiboot
  ret
.no_multiboot:
  mov al, "0"
  jmp error


check_cpuid:
  ; Store the flags into eax 
  pushfd
  pop eax
  ; store the flags for later
  mov ecx, eax
  ; flip the CPUID bit
  xor eax, 1 << 21
  ; copy the changed flags into FLAGS
  push eax
  popfd
  ; check if we were able to set CPUID
  pushfd
  pop eax
  ; restore origninal flags
  push ecx
  popfd
  ; see if the changes we did to CPUID worked
  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "1"
  jmp error

check_long_mode:
  mov eax, 0x80000000 ; implicit cpuid arg
  cpuid ; get cpu features
  cmp eax, 0x80000001 
  jb .no_long_mode ; if were not greater than 0x80000001 then weve no long mode 
  mov eax, 0x80000001 
  cpuid ; get extended processor info
  test edx, 1 << 29 ; check for the LM bit 
  jz .no_long_mode
  ret 
.no_long_mode:
  mov al, "2" 
  jmp error
  

error:
  mov dword [0xb8000], 0x4f524f45
  mov dword [0xb8004], 0x4f3a4f52
  mov dword [0xb8008], 0x4f204f20
  mov byte  [0xb800a], al
  hlt

section .bss


align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
p1_tables:
    resb 4096 * P1_COUNT

boot_stack_bottom:
    resb 64
boot_stack_top:

section .rodata
gdt64: ; long mode gdt
    dq 0 ; zero entry
.code: equ $ - gdt64 ; new
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segm
.pointer:
    dw $ - gdt64 - 1
    dq gdt64
