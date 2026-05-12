#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

BUILD ?= build

build_dir := $(BUILD)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

sel4_prefix := $(SEL4_INSTALL_DIR)

kernel := $(SEL4_INSTALL_DIR)/bin/kernel.elf

app_crate := example
app := $(build_dir)/$(app_crate).elf

$(app): $(app).intermediate

# SEL4_TARGET_PREFIX is used by build.rs scripts of various rust-sel4 crates to locate seL4
# configuration and libsel4 headers.
.INTERMDIATE: $(app).intermediate
$(app).intermediate:
	SEL4_PREFIX=$(sel4_prefix) \
		cargo build \
			--target-dir $(build_dir)/target \
			--artifact-dir $(build_dir) \
			-p $(app_crate)

kernel32 := $(BUILD)/kernel32.elf

$(kernel32):
	objcopy -O elf32-i386 $(kernel) $@

qemu_cmd := \
	qemu-system-x86_64 \
		-cpu Nehalem,-vme,+pdpe1gb,-xsave,-xsaveopt,-xsavec,-fsgsbase,-invpcid,+syscall,+lm,enforce \
		-m size=512M \
		-serial mon:stdio \
		-nographic \
		-kernel $(kernel32) \
		-initrd $(app)

.PHONY: run
run: $(app) $(kernel32)
	$(qemu_cmd)

.PHONY: test
test: test.py $(app)
	python3 $< $(qemu_cmd)
