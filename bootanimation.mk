BOOTANIMATION_NEXWELL_TARGET := $(PRODUCT_OUT)/system/media/bootanimation.zip

BOOTANIMATION_NEXWELL_FILES = $(shell find device/nexwell/bootanimation -type f)
BOOTANIMATION_NEXWELL_ARCHIVE = device/nexwell/bootanimation.zip

$(BOOTANIMATION_NEXWELL_ARCHIVE): $(BOOTANIMATION_NEXWELL_FILES)
	rm -f device/nexwell/bootanimation.zip
	cd device/nexwell/bootanimation && zip -0r ../bootanimation.zip *

$(BOOTANIMATION_NEXWELL_TARGET): $(BOOTANIMATION_NEXWELL_ARCHIVE)
	cp $(BOOTANIMATION_NEXWELL_ARCHIVE) $(BOOTANIMATION_NEXWELL_TARGET)

.PHONY: bootanimation_nexwell
bootanimation_nexwell: $(BOOTANIMATION_NEXWELL_TARGET)

