LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

# kernel from src
#include kernel/xiaomi/libra/AndroidKernel.mk

ALL_PREBUILT += $(INSTALLED_KERNEL_TARGET)

# include the non-open-source counterpart to this file
-include vendor/xiaomi/libra/AndroidBoardVendor.mk

# Create symbolic links
$(shell mkdir -p $(TARGET_OUT_ETC)/firmware/wlan/qca_cld; \
        ln -sf /system/etc/wifi/WCNSS_qcom_cfg.ini \
        $(TARGET_OUT_ETC)/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini; \
        ln -sf /persist/wlan_mac.bin \
        $(TARGET_OUT_ETC)/firmware/wlan/qca_cld/wlan_mac.bin; \
	mkdir -p $(TARGET_OUT)/vendor/lib; \
	ln -sf egl/libEGL_adreno.so $(TARGET_OUT)/vendor/lib/libEGL_adreno.so; \
	mkdir -p $(TARGET_OUT)/vendor/lib64; \
	ln -sf egl/libEGL_adreno.so $(TARGET_OUT)/vendor/lib64/libEGL_adreno.so )

#	mkdir -p $(TARGET_OUT)/lib/modules;
#	ln -sf qca_cld/qca_cld_wlan.ko $(TARGET_OUT)/lib/modules/wlan.ko;

