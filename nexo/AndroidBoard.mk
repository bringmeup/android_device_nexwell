LOCAL_PATH := $(call my-dir)

ifeq ($(PREBUILT_FSL_IMX_CODEC),true)
-include device/fsl-codec/fsl-codec.mk
endif
include device/fsl-proprietary/media-profile/media-profile.mk

TARGET_BOOTLOADER_DIR=nexo
TARGET_BOARD_DTS_CONFIG= \
	imx6q:imx6q-nexo.dtb imx6dl:imx6dl-nexo.dtb imx6q:imx6q-nitrogen6_max.dtb \
	imx6qp:imx6qp-nitrogen6_max.dtb imx6q:imx6q-sabrelite.dtb imx6dl:imx6dl-nitrogen6_vm.dtb \
	imx6qp:imx6qp-nitrogen6_som2.dtb imx6q:imx6q-nitrogen6_som2.dtb imx6dl:imx6dl-nitrogen6_som2.dtb

include device/nexwell/bootscript.mk
include device/nexwell/ramdisk.mk
