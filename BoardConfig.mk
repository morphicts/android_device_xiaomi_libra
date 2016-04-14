LOCAL_PATH := device/xiaomi/libra

# inherit from the proprietary version
-include vendor/xiaomi/libra/BoardConfigVendor.mk

# TS mod mi4c flag, we can use this across the platform if needed
COMMON_GLOBAL_CFLAGS += -DTS_MOD_MI4C

# Platform
TARGET_BOARD_PLATFORM := msm8992
TARGET_BOARD_PLATFORM_GPU := qcom-adreno418
TARGET_BOARD_SUFFIX := _64

BOOTLOADER_PLATFORM := msm8994
TARGET_BOOTLOADER_BOARD_NAME := MSM8992
TARGET_NO_BOOTLOADER := true

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53.a57
TARGET_CPU_CORTEX_A53 := true
TARGET_CPU_SMP := true

#TARGET_USE_QCOM_BIONIC_OPTIMIZATION := true
TARGET_USES_64_BIT_BINDER := true
TARGET_NO_SENSOR_PERMISSION_CHECK := true

# Use dlmalloc instead of jemalloc for mallocs
#MALLOC_IMPL := dlmalloc

# Graphics
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
#TARGET_USE_COMPAT_GRALLOC_ALIGN := true
#BOARD_EGL_NEEDS_HANDLE_VALUE := true
#VSYNC_EVENT_PHASE_OFFSET_NS := 2500000
#SF_VSYNC_EVENT_PHASE_OFFSET_NS := 0000000

TARGET_USES_ION := true
TARGET_USES_OVERLAY := true
USE_OPENGL_RENDERER := true
TARGET_USES_C2D_COMPOSITION := true
#BOARD_USE_LEGACY_UI := true
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048

MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024

HAVE_ADRENO_SOURCE := false
#OVERRIDE_RS_DRIVER := libRSDriver_adreno.so

# Include an expanded selection of fonts
EXTENDED_FONT_FOOTPRINT := true

# CM Hardware
BOARD_USES_CYANOGEN_HARDWARE := true
BOARD_HARDWARE_CLASS += hardware/cyanogen

# ANT+
BOARD_ANT_WIRELESS_DEVICE := "vfs-prerelease"

# Audio
BOARD_USES_ALSA_AUDIO := true
TARGET_NO_RPC := true
BOARD_SUPPORTS_SOUND_TRIGGER := false

AUDIO_USE_LL_AS_PRIMARY_OUTPUT := true
#AUDIO_FEATURE_ENABLED_ACDB_LICENSE := true
AUDIO_FEATURE_ENABLED_COMPRESS_CAPTURE := true
AUDIO_FEATURE_ENABLED_COMPRESS_VOIP := true
#AUDIO_FEATURE_ENABLED_DS2_DOLBY_DAP := true
AUDIO_FEATURE_ENABLED_EXTN_FORMATS := true
#AUDIO_FEATURE_ENABLED_FLAC_OFFLOAD := true
AUDIO_FEATURE_ENABLED_FLUENCE := true
AUDIO_FEATURE_ENABLED_HFP := true
AUDIO_FEATURE_ENABLED_KPI_OPTIMIZE := true
AUDIO_FEATURE_ENABLED_LOW_LATENCY_CAPTURE := true
AUDIO_FEATURE_ENABLED_MULTI_VOICE_SESSIONS := true
AUDIO_FEATURE_ENABLED_PCM_OFFLOAD := true
AUDIO_FEATURE_ENABLED_PCM_OFFLOAD_24 := true
#AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
# No incall music in CM13
AUDIO_FEATURE_ENABLED_INCALL_MUSIC := false
# No FM on mi4c
AUDIO_FEATURE_ENABLED_FM := false

# Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true
BOARD_HAS_QCA_BT_ROME := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/xiaomi/libra/bluetooth

# Build with Clang by default
#USE_CLANG_PLATFORM_BUILD := true

# Kernel
TARGET_KERNEL_SOURCE := kernel/xiaomi/libra
#TARGET_KERNEL_CONFIG := libra_user_defconfig
#TARGET_KERNEL_CONFIG := cyanogenmod_libra_defconfig
TARGET_KERNEL_CONFIG := ts_libra_defconfig

ifeq ($(TWRP_BUILD),)
# ROM
BOARD_KERNEL_CMDLINE := console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 boot_cpus=0-5 ramoops_memreserve=2M androidboot.selinux=permissive
else
# TWRP
BOARD_KERNEL_CMDLINE := console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 boot_cpus=0-5 ramoops_memreserve=2M androidboot.selinux=permissive ts_dsx_skip_fwu=1
endif

BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x0008000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET     := 0x02000000

BOARD_KERNEL_SEPARATED_DT := true
BOARD_HAS_NO_SELECT_BUTTON := true

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-

BOARD_DTBTOOL_ARGS := -2
BOARD_KERNEL_IMAGE_NAME := Image

WLAN_MODULES:
	mkdir -p $(KERNEL_MODULES_OUT)/qca_cld
	mv $(KERNEL_MODULES_OUT)/wlan.ko $(KERNEL_MODULES_OUT)/qca_cld/qca_cld_wlan.ko
	ln -sf /system/lib/modules/qca_cld/qca_cld_wlan.ko $(TARGET_OUT)/lib/modules/wlan.ko
TARGET_KERNEL_MODULES += WLAN_MODULES

# fix this up by examining /proc/mtd on a running device
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864 #64M
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864 #64M
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2013265920 #1920M
BOARD_CACHEIMAGE_PARTITION_SIZE := 402653184 #384M
BOARD_USERDATAIMAGE_PARTITION_SIZE := 27980184576 #26G
BOARD_FLASH_BLOCK_SIZE := 131072 #262144 #(BOARD_KERNEL_PAGESIZE * 64)
BOARD_VOLD_EMMC_SHARES_DEV_MAJOR := true

# Ext4
TARGET_USERIMAGES_USE_EXT4 := true
# f2fs support
TARGET_USERIMAGES_USE_F2FS := true

MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024

#TARGET_REQUIRES_SYNCHRONOUS_SETSURFACE := true

TARGET_PLATFORM_DEVICE_BASE := /devices/soc.0/
TARGET_INIT_VENDOR_LIB := libinit_msm

TARGET_LDPRELOAD := libNimsWrap.so

TARGET_PROVIDES_LIBLIGHT := true

# Camera
USE_CAMERA_STUB := true
USE_DEVICE_SPECIFIC_CAMERA := true
#BOARD_VENDOR_QCOM_CAMERA_USES_NV21_FORMAT := true
COMMON_GLOBAL_CFLAGS += -DCAMERA_VENDOR_L_COMPAT

# Force camera module to be compiled only in 32-bit mode on 64-bit systems
# Once camera module can run in the native mode of the system (either
# 32-bit or 64-bit), the following line should be deleted
BOARD_QTI_CAMERA_32BIT_ONLY := true

# Charger
BOARD_CHARGER_ENABLE_SUSPEND := true
BOARD_CHARGER_SHOW_PERCENTAGE := true

# Enable HW based full disk encryption
TARGET_HW_DISK_ENCRYPTION := true

# Power
#TARGET_POWERHAL_VARIANT := qcom
TARGET_POWERHAL_VARIANT := tspower

# Qualcomm support
BOARD_USES_QCOM_HARDWARE := true
TARGET_ENABLE_QC_AV_ENHANCEMENTS := true

# Keymaster
TARGET_KEYMASTER_WAIT_FOR_QSEE := true

# Time services
BOARD_USES_QC_TIME_SERVICES := true

# CMHW (dt2w)
BOARD_HARDWARE_CLASS += device/xiaomi/libra/cmhw

# Ril
TARGET_RIL_VARIANT := caf
SIM_COUNT := 2
TARGET_GLOBAL_CFLAGS += -DANDROID_MULTI_SIM
TARGET_GLOBAL_CPPFLAGS += -DANDROID_MULTI_SIM

# Flags for modem (we still have an old modem)
#COMMON_GLOBAL_CFLAGS += -DUSE_RIL_VERSION_10
#COMMON_GLOBAL_CPPFLAGS += -DUSE_RIL_VERSION_10

# Added to indicate that protobuf-c is supported in this build
PROTOBUF_SUPPORTED := true

# Cpusets
ENABLE_CPUSETS := true

# Wifi
BOARD_HAS_QCOM_WLAN := true
BOARD_HAS_QCOM_WLAN_SDK := true
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_qcwcn
BOARD_WLAN_DEVICE := qcwcn
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_qcwcn
TARGET_USES_WCNSS_CTRL := true
WIFI_DRIVER_MODULE_PATH := "/system/lib/modules/wlan.ko"
WIFI_DRIVER_MODULE_NAME := "wlan"
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WPA_SUPPLICANT_VERSION := VER_0_8_X
TARGET_USES_QCOM_WCNSS_QMI      := true
TARGET_USES_WCNSS_MAC_ADDR_REV  := true

# healthd
RED_LED_PATH := /sys/class/leds/red/brightness
GREEN_LED_PATH := /sys/class/leds/green/brightness
BLUE_LED_PATH := /sys/class/leds/blue/brightness
BACKLIGHT_PATH := /sys/class/leds/lcd-backlight/brightness

# Boot-animation
TARGET_BOOTANIMATION_PRELOAD := true
TARGET_BOOTANIMATION_TEXTURE_CACHE := true
TARGET_BOOTANIMATION_USE_RGB565 := true

# TWRP
TW_THEME := portrait_hdpi
TARGET_RECOVERY_PIXEL_FORMAT := "RGBA_8888"
RECOVERY_GRAPHICS_USE_LINELENGTH := true
DEVICE_RESOLUTION := 1080x1920
RECOVERY_SDCARD_ON_DATA := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_L_CRYPTO := true
TW_FLASH_FROM_STORAGE := true
TW_INTERNAL_STORAGE_PATH := "/data/media/0"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/usb-otg"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "usb-otg"
BOARD_HAS_NO_REAL_SDCARD := true
TW_NO_USB_STORAGE := true
TW_MAX_BRIGHTNESS := 255
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TARGET_RECOVERY_QCOM_RTC_FIX := true
BOARD_SUPPRESS_SECURE_ERASE := true
TWHAVE_SELINUX := true
TW_DOWNLOAD_MODE := true
TW_REBOOT_BOOTLOADER := true
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_NTFS_3G := true

#ifeq ($(TWRP_BUILD),)
# Use following recovery fstab when building ROM:
#RECOVERY_FSTAB_VERSION := 2
#TARGET_RECOVERY_FSTAB := device/xiaomi/libra/prebuilt/ramdisk/fstab.qcom
#else
# Use following recovery fstab when building TWRP recovery:
RECOVERY_FSTAB_VERSION := 1
TARGET_RECOVERY_FSTAB := device/xiaomi/libra/twrp.fstab
#endif

# Enable dex pre-opt to speed up initial boot
#ifneq ($(TARGET_USES_AOSP),true)
#  ifeq ($(HOST_OS),linux)
#    ifeq ($(WITH_DEXPREOPT),)
#      WITH_DEXPREOPT := true
#      ifneq ($(TARGET_BUILD_VARIANT),user)
        # Retain classes.dex in APK's for non-user builds
#        DEX_PREOPT_DEFAULT := nostripping
#      endif
#    endif
#  endif
#endif

# SELinux
BOARD_SEPOLICY_DIRS += device/xiaomi/libra/sepolicy
include device/qcom/sepolicy/sepolicy.mk

