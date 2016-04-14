#!/system/bin/sh

LOG_TAG="TS PowerHAL (sh)"
LOG_NAME="${0}:"

loge ()
{
  /system/bin/log -t $LOG_TAG -p e "$@"
}

logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$@"
}

action=$1
value=$2
logi "action is ($action)"
logi "value is ($value)"

profile=`getprop persist.ts.profile`
logi "persist.ts.profile is ($profile)"

# Handle display on/off
if [ "$action" = "set_interactive" ]; then
	if [ "$value" = "0" ]; then
		# Display off
		# Turn off big cluster while display is off
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
	else
		# Display on
		# Turn on big cluster while display is on
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
	fi
	exit 0
fi

perfd_running=$(getprop "init.svc.perfd")
if [ "$perfd_running" = "running" ]; then
	# Stop perfd while tuning params
	logi "Stopping perfd"
	stop perfd
fi

# Disable thermal and bcl hotplug to switch governor
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
# Make sure CPU4 is online for config
echo 1 > /sys/devices/system/cpu/cpu4/online

# Handle power profile change
case "$profile" in
    # PROFILE_POWER_SAVE = 0
	# PROFILE_BIAS_POWER_SAVE = 3
	# Power save profile
    #   This mode sacrifices performance for maximum power saving.    
    # Power save bias profile
    #   This mode decreases performance slightly to improve power savings.     
    "0"|"3")
		logi "POWER_SAVE / PROFILE_BIAS_POWER_SAVE"

		# Configure governor settings for little cluster
        echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
        echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
        echo 99 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
        echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
		echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo "65 460800:63 600000:45 672000:35 787200:47 864000:80 960000:85 1248000:95 1440000:99" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads        
        echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
		echo "0" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration        
		echo "1248000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

		# Big cluster always off
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		
		# 0ms input boost
		echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms		

		echo 5 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

		for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
		do
			echo "powersave" > $devfreq_gov
		done
		for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
		do
			echo "powersave" > $devfreq_gov
		done
        ;;

	# PROFILE_BALANCED = 1
    # Balanced power profile
    #   The default mode for balanced power savings and performance
	"1")
		logi "BALANCED"

		# Configure governor settings for little cluster
        echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
        echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
        echo 99 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
        echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
		echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads        
        echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
		echo "0" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
		echo "1440000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		
        # Configure governor settings for big cluster
        echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif
        echo "50000 1440000:20000" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
        echo 80 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
        echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
        echo 633600 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        echo "95 633600:75 768000:80 864000:81 960000:81 1248000:85 1344000:85 1440000:85 1536000:85 1632000:86 1632000:86 1824000:87" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
		echo "0" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
        echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis
        
		# Big cluster hotplugged by core_ctl
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		
		# 40ms input boost
		echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

		echo 2 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

		for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
		do
			echo "bw_hwmon" > $devfreq_gov
		done
		for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
		do
			echo "cpufreq" > $devfreq_gov
		done
        ;;

	# PROFILE_BIAS_PERFORMANCE = 4
    # Performance bias profile
    #   This mode improves performance at the cost of some power.    
	"4")
		logi "BIAS_PERFORMANCE"

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
		echo "1440000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq   
		
        # Configure governor settings for big cluster
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

		# Big cluster always on
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		
		# 40ms input boost
		echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

		echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 0 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

		echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

		for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
		do
			echo "bw_hwmon" > $devfreq_gov
		done
		for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
		do
			echo "cpufreq" > $devfreq_gov
		done		
        ;;

	# PROFILE_HIGH_PERFORMANCE = 2
	# High-performance profile
    #   This mode sacrifices power for maximum performance
	"2")
		logi "HIGH_PERFORMANCE"

		# Configure governor settings for little cluster
		echo "1440000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

		# Configure governor settings for big cluster
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

		# Big cluster always on
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		
		# 100ms input boost
		echo 100 > /sys/module/cpu_boost/parameters/input_boost_ms		

		for devfreq_gov in /sys/class/devfreq/qcom,cpubw*/governor
		do
			echo "performance" > $devfreq_gov
		done
		for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
		do
			echo "performance" > $devfreq_gov
		done
        ;;

    *)
        ;;
esac

# Re-enable thermal and BCL hotplug
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

if [ "$perfd_running" = "running" ]; then
	# Restart perfd
	logi "Restarting perfd"
	rm /data/system/perfd/default_values
	start perfd
fi

