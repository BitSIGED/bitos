arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
# Some systems have grub-mkrescue2 instead of grub-mkrescue, so we check for both
grub_mkrescue := $(shell command -v grub-mkrescue 2>/dev/null || command -v grub2-mkrescue 2>/dev/null)
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))
target ?= $(arch)-bitos
rust_os := target/$(target)/debug/libbitos.a

.PHONY: all clean run iso debug gdb

all: $(kernel)

clean:
	@cargo +nightly clean
	@rm -rf build
	@rm -f qemu.log

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

debug: $(iso)
	@qemu-system-x86_64 -cdrom $(iso) -s -S

gdb:
	@rust-gdb build/kernel-x86_64.bin -ex "target remote :1234"

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@if [ -z "$(grub_mkrescue)" ]; then \
		echo "error: grub2 mkrescue is required to build the ISO"; \
		exit 127; \
	fi
	@$(grub_mkrescue) -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): $(rust_os) $(assembly_object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) \
		$(assembly_object_files) $(rust_os)

$(rust_os): Cargo.toml src/lib.rs x86_64-bitos.json .cargo/config.toml
	@cargo +nightly build -Zbuild-std=core,compiler_builtins,alloc --target $(target).json

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
