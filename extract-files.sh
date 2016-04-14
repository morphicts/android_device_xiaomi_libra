#!/bin/bash

set -e
set +e

VENDOR=xiaomi
DEVICE=libra

#ROM_PATH=/mnt/6c105da9-6d22-43e5-9ccb-d58438eba144/mi4c_cm13/miui/miui_MI4c_V7.2.3.0.LXKCNDA_da1ff68dd2_5.1
ROM_PATH=$1

if [ ! -d "$ROM_PATH" ]; then
	echo "Parameter does not point to any folder"
	exit 1
fi

# get absolute path
ROM_PATH=$(realpath $ROM_PATH)

SYSTEM_IMG_PATH=$ROM_PATH/system
BOOT_PATH=$ROM_PATH/boot

if [ ! -d "$SYSTEM_IMG_PATH" ]; then
	echo "ROM folder does not contain system folder"
	echo "system.img must be extracted to $ROM_PATH/system folder"
	exit 2
fi

if [ ! -d "$BOOT_PATH" ]; then
	echo "ROM folder does not contain boot folder"
	echo "boot.img must be extracted to $ROM_PATH/boot folder"
	exit 3
fi

# Charge only mode
mkdir -p ./prebuilt/ramdisk/sbin
cp -f $BOOT_PATH/ramdisk/sbin/chargeonlymode ./prebuilt/ramdisk/sbin

# Recovery crypto support
mkdir -p ./prebuilt/recovery/sbin
mkdir -p ./prebuilt/recovery/lib64/hw
cp -f $ROM_PATH/system/vendor/lib64/libdrmfs.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/libQSEEComAPI.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/libssd.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/libdiag.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/libdrmtime.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/librpmb.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/vendor/lib64/libtime_genoff.so ./prebuilt/recovery/sbin
cp -f $ROM_PATH/system/bin/qseecomd ./prebuilt/recovery/sbin

function extract() {
    for FILE in `egrep -v '(^#|^$)' $1`; do
        OLDIFS=$IFS IFS=":" PARSING_ARRAY=($FILE) IFS=$OLDIFS
        FILE=`echo ${PARSING_ARRAY[0]} | sed -e "s/^-//g"`
        DEST=${PARSING_ARRAY[1]}
        if [ -z $DEST ]; then
            DEST=$FILE
        fi
        DIR=`dirname $FILE`
        if [ ! -d $2/$DIR ]; then
            mkdir -p $2/$DIR
        fi
     
		if [ "SYSTEM_IMG_PATH" != "" ]; then

	  		APK=$SYSTEM_IMG_PATH/$DEST
	  		if [ "${APK##*.}" = "apk" ]; then
 				./deodex/deodex-app $ROM_PATH $APK
	  		fi
	  		if [ "${APK##*.}" = "jar" ]; then
 				./deodex/deodex-app $ROM_PATH $APK
	  		fi

	  		# Extract from path
	  		cp $SYSTEM_IMG_PATH/$DEST $2/$DEST
	  		# if file does not exist try OEM target
			if [ "$?" != "0" ]; then
				cp $SYSTEM_IMG_PATH/$FILE $2/$DEST
				if [ "$?" != "0" ]; then
					echo "ERROR"
				fi
			fi
        fi
    done
}

DEVBASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $DEVBASE/*

extract ../../$VENDOR/$DEVICE/proprietary-files.txt $DEVBASE

./setup-makefiles.sh
