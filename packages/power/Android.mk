LOCAL_PATH := $(call my-dir)

# Hey Mr. Make Author, DIAF PLX
ifeq ($(TARGET_POWERHAL_VARIANT),tspower)

# HAL module implemenation stored in
# hw/<POWERS_HARDWARE_MODULE_ID>.<ro.hardware>.so
include $(CLEAR_VARS)

LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_PROPRIETARY_MODULE := true
LOCAL_SHARED_LIBRARIES := liblog libcutils libdl
LOCAL_SRC_FILES := power.c

LOCAL_MODULE := power.$(TARGET_BOARD_PLATFORM)
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)

endif # TARGET_POWERHAL_VARIANT == tspower
