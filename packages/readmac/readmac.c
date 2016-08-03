/*
 * Copyright (C) 2013 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#define LOG_NDEBUG 0
#define LOG_TAG "ts-readmac"
#define VERSION "2"

#include <cutils/log.h>

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <sys/types.h>

#include <cutils/properties.h>

/******************************************************************************/

#define WLAN_MAC_BIN "/persist/wlan_mac.bin"
#define FILE_STAMP "# TS readmac v" VERSION " generated file"

extern int qmi_nv_read_wlan_mac(char** mac);

// Xiaomi MAC OUI's
static char *xiaomi_mac_ouis =
	"009EC8 " \
	"0C1DAF " \
	"102AB3 " \
	"14F65A " \
	"185936 " \
	"2082C0 " \
	"286C07 " \
	"28E31F " \
	"3480B3 " \
	"38A4ED " \
	"584498 " \
	"640980 " \
	"64B473 " \
	"64CC2E " \
	"68DFDD " \
	"742344 " \
	"7451BA " \
	"7C1DD9 " \
	"8CBEBE " \
	"98FAE3 " \
	"9C99A0 " \
	"A086C6 " \
	"ACF7F3 " \
	"B0E235 " \
	"C46AB7 " \
	"D4970B " \
	"F0B429 " \
	"F48B32 " \
	"F8A45F " \
	"FC64BA ";

static int check_wlan_mac_bin_file()
{
	char content[1024];	
	size_t read_len;
	FILE *fp = fopen(WLAN_MAC_BIN, "r");
	if (fp != NULL) {
		memset(content, 0, sizeof(content));
		read_len = fread(content, 1, sizeof(content)-1, fp);
		fclose(fp);

		content[read_len] = '\0';		
		ALOGV(WLAN_MAC_BIN " content '%s'", content);	

		if (strstr(content, FILE_STAMP) == NULL)
		{
			ALOGE(WLAN_MAC_BIN " Missing/invalid file stamp");	
			return 1;
		}

		if (strstr(content, "Intf0MacAddress") == NULL)
		{
			ALOGE(WLAN_MAC_BIN " Missing value Intf0MacAddress");	
			return 1;
		}

		if (strstr(content, "Intf1MacAddress") == NULL)
		{
			ALOGE(WLAN_MAC_BIN " Missing value Intf1MacAddress");	
			return 1;
		}

		return 0;
	} else {
		ALOGE(WLAN_MAC_BIN " file not found!");	
	}
	return 1;
}

static int is_valid_mac(const char *mac)
{
	char tmp[7];
	strncpy(tmp, mac, 6);
	tmp[6] = '\0';
	return (strstr(xiaomi_mac_ouis, tmp) != NULL) ? 0 : 1;
}

static void reverse_mac_bytes(unsigned char *wlan_addr)
{
    unsigned char *lo = wlan_addr;
    unsigned char *hi = wlan_addr + 5;
    unsigned char swap;
    while (lo < hi) {
        swap = *lo;
        *lo++ = *hi;
        *hi-- = swap;
    }
}

int main(int argc, char **argv)
{
	unsigned char wlan_addr[6] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, };
	char* nv_wlan_mac = NULL;
	char ts_mac[PROPERTY_VALUE_MAX];
	char mac_str[PROPERTY_VALUE_MAX];
	int ret, i;
	FILE *fp;

	(void)argc;
	(void)argv;

	if (!check_wlan_mac_bin_file())
	{
		ALOGV(WLAN_MAC_BIN " file already valid");
		return 0;
	}

	// read wlan mac address from modem NV
	ret = qmi_nv_read_wlan_mac(&nv_wlan_mac);
	if (!nv_wlan_mac)
	{
		ALOGE("qmi_nv_read_wlan_mac error %d", ret);
		return 1;
	}
	for (i=0; i<6; i++) {
	    wlan_addr[i] = nv_wlan_mac[i];
	}

    sprintf(mac_str, "%02X%02X%02X%02X%02X%02X", 
		wlan_addr[0], wlan_addr[1], wlan_addr[2], wlan_addr[3], wlan_addr[4], wlan_addr[5]);
	ALOGV(WLAN_MAC_BIN " Got MAC from NV: %s", mac_str);

	// Check for MAC OUI validity
	if (is_valid_mac(mac_str))
	{
		ALOGE(WLAN_MAC_BIN " %s is invalid MAC, trying reversed", mac_str);

		// Try reversed mac
		reverse_mac_bytes(wlan_addr);
	    sprintf(mac_str, "%02X%02X%02X%02X%02X%02X", 
			wlan_addr[0], wlan_addr[1], wlan_addr[2], wlan_addr[3], wlan_addr[4], wlan_addr[5]);

		if (is_valid_mac(mac_str))
		{
			// Huh..?? Something crap in NV?
			// Lets generate something remotely sane
			ALOGE(WLAN_MAC_BIN " Reversed MAC is invalid! (%s)", mac_str);
			wlan_addr[0] = 0x00;
			wlan_addr[1] = 0x9E;
			wlan_addr[2] = 0xC8;
			wlan_addr[3] = (rand() % 0xFF);
			wlan_addr[4] = (rand() % 0xFF);
			wlan_addr[5] = (rand() % 0xFF);
		    sprintf(mac_str, "%02X%02X%02X%02X%02X%02X", 
				wlan_addr[0], wlan_addr[1], wlan_addr[2], wlan_addr[3], wlan_addr[4], wlan_addr[5]);
			ALOGV(WLAN_MAC_BIN " Generated MAC: %s", mac_str);
		} else {
			ALOGV(WLAN_MAC_BIN " Reversed MAC is valid! (%s)", mac_str);
		}
	} else {
		ALOGV(WLAN_MAC_BIN " %s is valid MAC", mac_str);
	}

	fp = fopen(WLAN_MAC_BIN, "w");
	fprintf(fp, FILE_STAMP "\n");
	fprintf(fp, "Intf0MacAddress=%02X%02X%02X%02X%02X%02X\n",
		wlan_addr[0], wlan_addr[1], wlan_addr[2], wlan_addr[3], wlan_addr[4], wlan_addr[5]);
	fprintf(fp, "Intf1MacAddress=%02X%02X%02X%02X%02X%02X\n",
		wlan_addr[0], wlan_addr[1], wlan_addr[2], wlan_addr[3], wlan_addr[4], (unsigned char)(wlan_addr[5]+1));
	fprintf(fp, "END\n");
	fclose(fp);

	ALOGV(WLAN_MAC_BIN " written; mac %s", mac_str);

	property_get("persist.sys.wifi.mac", ts_mac, "");
	if (strcmp(ts_mac, mac_str))
	{
	    property_set("persist.sys.wifi.mac", mac_str);
	    ALOGV("Set persist.sys.wifi.mac -> '%s'\n", mac_str);
	}

    return 0;
}

