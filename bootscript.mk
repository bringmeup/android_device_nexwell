BOOTSCRIPT_TARGET := $(PRODUCT_OUT)/boot/6x_bootscript
$(BOOTSCRIPT_TARGET): device/nexwell/$(TARGET_BOOTLOADER_DIR)/6x_bootscript.txt
	mkdir -p $(dir $@)
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d $< $@

UPGRADE_TARGET := $(PRODUCT_OUT)/boot/upgrade.scr
$(UPGRADE_TARGET): device/nexwell/$(TARGET_BOOTLOADER_DIR)/upgrade.txt
	mkdir -p $(dir $@)
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "upgrade script" -d $< $@

.PHONY: bootscript
bootscript: $(BOOTSCRIPT_TARGET) $(UPGRADE_TARGET)

droidcore: bootscript
bootimage: bootscript

