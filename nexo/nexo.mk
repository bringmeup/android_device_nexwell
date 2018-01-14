$(call inherit-product, device/fsl/imx6/imx6.mk)
$(call inherit-product-if-exists,vendor/google/products/gms.mk)
include device/nexwell/nexo/wifi_config.mk

# Overrides
PRODUCT_NAME := nexo
PRODUCT_DEVICE := nexo
PRODUCT_BRAND := nexwell
PRODUCT_MANUFACTURER := nexwell

USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
	device/nexwell/common/init.rc:root/init.freescale.rc \
	device/nexwell/common/init.recovery.rc:root/init.recovery.freescale.rc \
	device/nexwell/nexo/init.i.MX6DL.rc:root/init.freescale.i.MX6DL.rc \
	device/nexwell/nexo/init.i.MX6Q.rc:root/init.freescale.i.MX6Q.rc \
	device/nexwell/nexo/init.i.MX6QP.rc:root/init.freescale.i.MX6QP.rc \
	device/nexwell/nexo/required_hardware.xml:system/etc/permissions/required_hardware.xml \
	device/nexwell/nexo/ueventd.freescale.rc:root/ueventd.freescale.rc \
	device/nexwell/nexo/fstab.freescale:root/fstab.freescale \
	device/nexwell/scripts/setwlanmac:system/bin/setwlanmac \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/eGalax_Touch_Screen.idc \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/ILI210x_Touchscreen.idc \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/ft5x06.idc \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/tsc2004.idc \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/fusion_F0710A.idc \
	device/fsl/common/input/eGalax_Touch_Screen.idc:system/usr/idc/silead_ts.idc \
	device/nexwell/common/gsl1680.fw:system/etc/firmware/silead/gsl1680.fw \
	device/nexwell/common/audio_policy.conf:system/etc/audio_policy.conf \
	device/nexwell/common/audio_effects.conf:vendor/etc/audio_effects.conf \
	device/nexwell/common/audio_policy_configuration.xml:system/etc/audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/default_volume_tables.xml:system/etc/default_volume_tables.xml \
	frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:system/etc/audio_policy_volumes.xml \
	external/linux-firmware-imx/firmware/vpu/vpu_fw_imx6d.bin:system/lib/firmware/vpu/vpu_fw_imx6d.bin 	\
	external/linux-firmware-imx/firmware/vpu/vpu_fw_imx6q.bin:system/lib/firmware/vpu/vpu_fw_imx6q.bin

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

DEVICE_PACKAGE_OVERLAYS := \
	device/nexwell/nexo/overlay \
	device/nexwell/common/overlay

PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG += xlarge large tvdpi hdpi

ifeq ($(BOARD_WLAN_VENDOR),TI)
PRODUCT_PACKAGES += uim-sysfs \
	bt_sco_app \
	BluetoothSCOApp \
	TQS_D_1.7.ini

PRODUCT_COPY_FILES += \
	device/nexwell/common/init.ti.rc:root/init.bt-wlan.rc \
	device/nexwell/nexo/wl1271-nvs.bin:system/etc/firmware/ti-connectivity/wl1271-nvs.bin \
	device/nexwell/wl12xx/wl127x-fw-5-sr.bin:system/etc/firmware/ti-connectivity/wl127x-fw-5-sr.bin \
	device/nexwell/wl12xx/wl127x-fw-5-mr.bin:system/etc/firmware/ti-connectivity/wl127x-fw-5-mr.bin \
	device/nexwell/wl12xx/TIInit_7.6.15.bts:system/etc/firmware/ti-connectivity/TIInit_7.6.15.bts \
	device/nexwell/wl12xx/TIInit_7.2.31.bts:system/etc/firmware/ti-connectivity/TIInit_7.2.31.bts
endif

ifeq ($(BOARD_WLAN_VENDOR),BCM)
PRODUCT_PACKAGES += \
	audio.a2dp.default

PRODUCT_COPY_FILES += \
	device/nexwell/common/init.bcm.rc:root/init.bt-wlan.rc \
	device/nexwell/nexo/bt_vendor.conf:system/etc/bluetooth/bt_vendor.conf \
	device/nexwell/brcm/bcm43340.hcd:system/etc/firmware/bcm43340.hcd \
	device/nexwell/brcm/brcmfmac43340-sdio.bin:system/etc/firmware/brcm/brcmfmac43340-sdio.bin \
	device/nexwell/brcm/brcmfmac43340-sdio.txt:system/etc/firmware/brcm/brcmfmac43340-sdio.txt

BOARD_CUSTOM_BT_CONFIG := device/nexwell/nexo/libbt_vnd_nexo.conf
BOARD_WLAN_DEVICE_REV  := bcm4330_b2
WIFI_BAND              := 802_11_ABG
$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4330/device-bcm.mk)
endif

ifeq ($(BOARD_WLAN_VENDOR),QCA)
PRODUCT_PACKAGES += \
	qcacld_wlan.ko \
	bdwlan30.bin \
	otp30.bin \
	qca/tfbtfw11.tlv \
	qca/tfbtnv11.bin \
	qwlan30.bin \
	utf30.bin \
	utfbd30.bin \
	wlan/cfg.dat \
	wlan/qcom_cfg.ini

PRODUCT_COPY_FILES += \
	device/nexwell/common/init.qca.rc:root/init.bt-wlan.rc

# Specify which rfkill node to use since the first available (rfkill0) is the
# one from the HCI driver in the kernel (net/bluetooth/hci_core.c).
PRODUCT_PROPERTY_OVERRIDES += \
    ro.bt.rfkill.state=/sys/class/rfkill/rfkill1/state

BOARD_CUSTOM_BT_CONFIG := device/nexwell/nexo/libbt_vnd_nexo.conf
endif

# ExFat support
PRODUCT_PACKAGES += \
    fsck.exfat \
    libfuse \
    mkfs.exfat \
    mount.exfat

PRODUCT_PACKAGES += \
    dhcpcd.conf \
    hostapd.conf

PRODUCT_PACKAGES += \
	ethernet \
	CMFileManager \
	su

PRODUCT_COPY_FILES += \
    device/fsl-proprietary/gpu-viv/lib/egl/egl.cfg:system/lib/egl/egl.cfg

PRODUCT_PACKAGES += \
    libEGL_VIVANTE \
    libGLESv1_CM_VIVANTE \
    libGLESv2_VIVANTE \
    gralloc_viv.imx6 \
    hwcomposer_viv.imx6 \
    hwcomposer_fsl.imx6 \
    libGAL \
    libGLSLC \
    libVSC \
    libg2d \
    libgpuhelper
