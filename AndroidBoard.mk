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

#IMS_LIBS := libimscamera_jni.so libimsmedia_jni.so
#IMS_SYMLINKS := $(addprefix $(TARGET_OUT)/app/ims/lib/arm64/,$(notdir $(IMS_LIBS)))
#$(IMS_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
#	@echo "IMS lib link: $@"
#	@mkdir -p $(dir $@)
#	@rm -rf $@
#	$(hide) ln -sf /system/vendor/lib64/$(notdir $@) $@
#ALL_DEFAULT_INSTALLED_MODULES += $(IMS_SYMLINKS)

include device/xiaomi/libra/tftp.mk

# FW files
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/filesmap
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/bk2.img
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/rpm.mbn
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/pmic.mbn
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/NON-HLOS.bin
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/hyp.mbn
INSTALLED_RADIOIMAGE_TARGET += device/xiaomi/libra/radio/BTFM.bin

