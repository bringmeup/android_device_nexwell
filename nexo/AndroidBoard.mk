LOCAL_PATH := $(call my-dir)

ifeq ($(PREBUILT_FSL_IMX_CODEC),true)
include device/fsl-codec/fsl-codec.mk
endif
include device/fsl-proprietary/media-profile/media-profile.mk

TARGET_BOOTLOADER_CONFIG := nexo_defconfig
TARGET_BOOTLOADER_POSTFIX := imx
TARGET_BOOTLOADER_DIR=nexo
TARGET_BOARD_DTS_CONFIG= imx6qp:imx6qp-nexo.dtb

include device/nexwell/bootscript.mk
include device/nexwell/ramdisk.mk
include device/nexwell/bootanimation.mk

