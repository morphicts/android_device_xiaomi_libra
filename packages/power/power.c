/*
 * Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
 * Copyright (c) 2014, The CyanogenMod Project
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * *    * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of The Linux Foundation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define LOG_NIDEBUG 0

#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <stdlib.h>

#define LOG_TAG "TS PowerHAL"

#include <utils/Log.h>
#include <hardware/hardware.h>
#include <hardware/power.h>
#include <pthread.h>
#include <cutils/properties.h>

//#include "utils.h"
#include "power-common.h"
#include "power-feature.h"

static struct hw_module_methods_t power_module_methods = {
    .open = NULL,
};

static pthread_mutex_t hint_mutex = PTHREAD_MUTEX_INITIALIZER;

static void power_init(__attribute__((unused))struct power_module *module)
{
    ALOGI("TS power HAL initializing..");
}

void call_fname_ts_power_sh(const char *fname, const char *action, int value)
{
	char tmp_str[1024] = "";
    snprintf(tmp_str, sizeof(tmp_str), "sh %s %s %d", fname, action, value);
	ALOGI("%s: call (%s)", __func__, tmp_str);
	system(tmp_str);
}

#define USER_TS_POWER_SH "/data/ts_power.sh"
#define SYSTEM_TS_POWER_SH "/system/etc/ts_power.sh"

void call_ts_power_sh(const char *action, int value)
{
	// ALOGI("%s: (%s, %d)", __func__, action, value);

	if( access( USER_TS_POWER_SH, F_OK ) != -1 ) {
		call_fname_ts_power_sh(USER_TS_POWER_SH, action, value);
	}	
	else if( access( SYSTEM_TS_POWER_SH, F_OK ) != -1 ) {
		call_fname_ts_power_sh(SYSTEM_TS_POWER_SH, action, value);
	}
	else 
	{
		ALOGE("%s: ts_power.sh not found! (%s, %d)", __func__, action, value);
	}
}

void set_profile(int profile)
{
	char tmp_str[PROPERTY_VALUE_MAX] = "";
    snprintf(tmp_str, PROPERTY_VALUE_MAX, "%d", profile);
	property_set("persist.ts.profile", tmp_str);

	call_ts_power_sh("set_profile", profile);
}

static void power_hint(__attribute__((unused)) struct power_module *module, power_hint_t hint,
        void *data)
{
    pthread_mutex_lock(&hint_mutex);

    switch(hint) {
        case POWER_HINT_VSYNC:
        case POWER_HINT_INTERACTION:
        case POWER_HINT_CPU_BOOST:
        case POWER_HINT_LAUNCH_BOOST:
        case POWER_HINT_AUDIO:
        case POWER_HINT_LOW_POWER:
        case POWER_HINT_VIDEO_ENCODE:
        case POWER_HINT_VIDEO_DECODE:
        break;
        case POWER_HINT_SET_PROFILE:
			// ALOGI("%s: POWER_HINT_SET_PROFILE = %d", __func__, *(int32_t *)data);
			set_profile(*(int32_t *)data);			
			break;
        default:
        break;
    }

out:
    pthread_mutex_unlock(&hint_mutex);
}

int get_number_of_profiles()
{
    return 5;
}

void set_interactive(struct power_module *module, int on)
{
    pthread_mutex_lock(&hint_mutex);

    ALOGI("Got set_interactive hint: on %d", on);

	call_ts_power_sh("set_interactive", on);

out:
    pthread_mutex_unlock(&hint_mutex);
}

static int sysfs_write(char *path, char *s)
{
    char buf[80];
    int len;
    int ret = 0;
    int fd = open(path, O_WRONLY);

    if (fd < 0) {
        strerror_r(errno, buf, sizeof(buf));
        ALOGE("Error opening %s: %s\n", path, buf);
        return -1 ;
    }

    len = write(fd, s, strlen(s));
    if (len < 0) {
        strerror_r(errno, buf, sizeof(buf));
        ALOGE("Error writing to %s: %s\n", path, buf);

        ret = -1;
    }

    close(fd);

    return ret;
}

void set_feature(struct power_module *module, feature_t feature, int state)
{
	(void)module;

	if (feature == POWER_FEATURE_DOUBLE_TAP_TO_WAKE) 
	{
		char WAKEGESTURE_PATH[1024];
		char inputNum[PROPERTY_VALUE_MAX];
		char tmp_str[NODE_MAX];
		property_get("ts.touchinput", inputNum, "");
		if (inputNum[0]) 
		{
			sprintf(WAKEGESTURE_PATH, "/sys/class/input/%s/wake_gesture", inputNum);
		    snprintf(tmp_str, NODE_MAX, "%d", state);
		    sysfs_write(WAKEGESTURE_PATH, tmp_str);
		}
	}
}

int get_feature(struct power_module *module __unused, feature_t feature)
{
    if (feature == POWER_FEATURE_SUPPORTED_PROFILES) {
        return get_number_of_profiles();
    }
    return -1;
}

struct power_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = POWER_MODULE_API_VERSION_0_3,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = POWER_HARDWARE_MODULE_ID,
        .name = "TS MI4c Power HAL",
        .author = "Qualcomm/CyanogenMod/TeamSuperluminal",
        .methods = &power_module_methods,
    },

    .init = power_init,
    .powerHint = power_hint,
    .setInteractive = set_interactive,
    .setFeature = set_feature,
    .getFeature = get_feature
};
