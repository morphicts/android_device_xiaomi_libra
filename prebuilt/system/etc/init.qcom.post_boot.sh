#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# ensure at most one A57 is online when thermal hotplug is disabled
echo 0 > /sys/devices/system/cpu/cpu5/online
# in case CPU4 is online, limit its frequency
echo 960000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
# Limit A57 max freq from msm_perf module in case CPU 4 is offline
echo "4:960000 5:960000" > /sys/module/msm_performance/parameters/cpu_max_freq
# disable thermal bcl hotplug to switch governor
echo 0 > /sys/module/msm_thermal/core_control/enabled
for mode in /sys/devices/soc.0/qcom,bcl.*/mode
do
    echo -n disable > $mode
done
for hotplug_mask in /sys/devices/soc.0/qcom,bcl.*/hotplug_mask
do
    bcl_hotplug_mask=`cat $hotplug_mask`
    echo 0 > $hotplug_mask
done
for hotplug_soc_mask in /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask
do
    bcl_soc_hotplug_mask=`cat $hotplug_soc_mask`
    echo 0 > $hotplug_soc_mask
done
for mode in /sys/devices/soc.0/qcom,bcl.*/mode
do
    echo -n enable > $mode
done

# Disable CPU retention
echo 0 > /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled

# Disable L2 retention
echo 0 > /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled
echo 0 > /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled

# Configure governor settings for little cluster
echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
echo 90 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
echo 65 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
echo 80000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
echo "0" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
echo 384000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# online CPU4
echo 1 > /sys/devices/system/cpu/cpu4/online
# Best effort limiting for first time boot if msm_performance module is absent
echo 960000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
# configure governor settings for big cluster
echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif
echo 19000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
echo 80 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
echo 20000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
echo 1248000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
echo 85 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
echo "0" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
echo 80000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis
echo 384000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
# restore A57's max
cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq

# system permissions for performance profiles
chown -h system -R /sys/devices/system/cpu/
chown -h system -R /sys/module/msm_thermal/
chown -h system -R /sys/module/msm_performance/
chown -h system -R /sys/module/cpu_boost/
chown -h system -R /sys/devices/soc.0/qcom,bcl.*
chown -h system -R /sys/class/devfreq/qcom,cpubw*/
chown -h system -R /sys/class/devfreq/qcom,mincpubw*/
chown -h system -R /sys/class/kgsl/kgsl-3d0/

# ts power scripts permissions
chown -h system /system/etc/ts_power.sh
chown -h system /data/ts_power.sh

# re-enable thermal and BCL hotplug
echo 1 > /sys/module/msm_thermal/core_control/enabled
for mode in /sys/devices/soc.0/qcom,bcl.*/mode
do
    echo -n disable > $mode
done
for hotplug_mask in /sys/devices/soc.0/qcom,bcl.*/hotplug_mask
do
    echo $bcl_hotplug_mask > $hotplug_mask
done
for hotplug_soc_mask in /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask
do
    echo $bcl_soc_hotplug_mask > $hotplug_soc_mask
done
for mode in /sys/devices/soc.0/qcom,bcl.*/mode
do
    echo -n enable > $mode
done

# Plugin remaining A57s
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled
# Restore CPU 4 max freq from msm_performance
echo "4:4294967295 5:4294967295" > /sys/module/msm_performance/parameters/cpu_max_freq
# input boost configuration
#echo 0:864000 > /sys/module/cpu_boost/parameters/input_boost_freq
echo "0:600000 1:0 2:0 3:0 4:0 5:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
# core_ctl module
insmod /system/lib/modules/core_ctl.ko
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu4/core_ctl/is_big_cluster
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres
# Setting b.L scheduler parameters
echo 1 > /proc/sys/kernel/sched_migration_fixup
echo 15 > /proc/sys/kernel/sched_small_task
echo 20 > /proc/sys/kernel/sched_mostly_idle_load
echo 3 > /proc/sys/kernel/sched_mostly_idle_nr_run
echo 85 > /proc/sys/kernel/sched_upmigrate
echo 70 > /proc/sys/kernel/sched_downmigrate
echo 7500000 > /proc/sys/kernel/sched_cpu_high_irqload
echo 60 > /proc/sys/kernel/sched_heavy_task
echo 65 > /proc/sys/kernel/sched_init_task_load
echo 200000000 > /proc/sys/kernel/sched_min_runtime
echo 400000 > /proc/sys/kernel/sched_freq_inc_notify
echo 400000 > /proc/sys/kernel/sched_freq_dec_notify
#relax access permission for display power consumption
chown -h system /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
chown -h system /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
#enable rps static configuration
echo 8 > /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus
for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
do
    echo "bw_hwmon" > $devfreq_gov
done
for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
do
    echo "cpufreq" > $devfreq_gov
done

# set GPU default power level to 5 (180MHz) instead of 4 (305MHz)
echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

# Let core_ctl hotplug big cluster
# echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 

# android background processes are set to nice 10. Never schedule these on the a57s.
echo 9 > /proc/sys/kernel/sched_upmigrate_min_nice

# Configure foreground and background cpuset
echo "0-5" > /dev/cpuset/foreground/cpus
echo "4-5" > /dev/cpuset/foreground/boost/cpus
echo "0" > /dev/cpuset/background/cpus
echo "0-3" > /dev/cpuset/system-background/cpus

# Disable sched_boost
echo 0 > /proc/sys/kernel/sched_boost

# perfd
ext=$(getprop "ro.vendor.extension_library")
if [ "$ext" = "libqti-perfd-client.so" ]; then
	rm /data/system/perfd/default_values
	setprop ro.min_freq_0 384000
	setprop ro.min_freq_4 384000
	start perfd
fi

# Let kernel know our image version/variant/crm_version
image_version="10:"
image_version+=`getprop ro.build.id`
image_version+=":"
image_version+=`getprop ro.build.version.incremental`
image_variant=`getprop ro.product.name`
image_variant+="-"
image_variant+=`getprop ro.build.type`
oem_version=`getprop ro.build.version.codename`
echo 10 > /sys/devices/soc0/select_image
echo $image_version > /sys/devices/soc0/image_version
echo $image_variant > /sys/devices/soc0/image_variant
echo $oem_version > /sys/devices/soc0/image_crm_version

# Start RIDL/LogKit II client
#su -c /system/vendor/bin/startRIDL.sh &

# Fix GMS permissions regression..
# https://github.com/opengapps/opengapps/issues/200
pm grant com.google.android.gms android.permission.ACCESS_FINE_LOCATION
pm grant com.google.android.gms android.permission.ACCESS_COARSE_LOCATION

# Fix browser geolocation
pm grant com.android.browser android.permission.ACCESS_FINE_LOCATION
pm grant com.android.browser android.permission.ACCESS_COARSE_LOCATION

# Fix google contacts sync
pm grant com.google.android.syncadapters.contacts android.permission.READ_CONTACTS
pm grant com.google.android.syncadapters.contacts android.permission.WRITE_CONTACTS

# Fix google exchange contacts/calendar sync
pm grant com.google.android.gm.exchange android.permission.READ_CONTACTS
pm grant com.google.android.gm.exchange android.permission.WRITE_CONTACTS
pm grant com.google.android.gm.exchange android.permission.READ_CALENDAR
pm grant com.google.android.gm.exchange android.permission.WRITE_CALENDAR

