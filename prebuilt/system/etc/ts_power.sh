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
		case "$profile" in
		    "0"|"3")
				# POWER_SAVE / PROFILE_BIAS_POWER_SAVE -> big cluster off
				echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
			;;
		    "2"|"4")
				# HIGH_PERFORMANCE / BIAS_PERFORMANCE -> big cluster on
				echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
				echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
			;;
			*)
				# BALANCED
				echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
				echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
        	;;
		esac
	fi
	exit 0
fi

perfd_running=$(getprop "init.svc.perfd")
if [ "$perfd_running" = "running" ]; then
	# Stop perfd while tuning params
	logi "Stopping perfd"
	stop perfd
fi

# Make sure core_ctl does not hotplug big cluster
echo "2" > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
echo "2" > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus

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
echo "1" > /sys/devices/system/cpu/cpu4/online

# Just note to self 
# /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies                                                                                                             
# 384000 460800 600000 672000 787200 864000 960000 1248000 1440000
# /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies                                                                                                             
# 384000 480000 633600 768000 864000 960000 1248000 1344000 1440000 1536000 1632000 1689600 1824000
# /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies
# 600000000 490000000 450000000 367000000 300000000 180000000
# /sys/class/kgsl/kgsl-3d0/devfreq/available_governors                                                                                                                           
# spdm_bw_hyp bw_hwmon bw_vbif gpubw_mon msm-adreno-tz cpufreq userspace powersave performance simple_ondemand

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
		#echo "smartmax" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
        echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
        echo 99 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
        echo 50000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
		echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads        
        echo 50000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
		echo "0" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
		echo "1440000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

		# Big cluster always off
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		
		# 0ms input boost
		echo 0 > /sys/module/cpu_boost/parameters/input_boost_freq
		echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms		

		# 180Mhz GPU max speed
		echo "powersave" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
		echo 180000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
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
        echo 50000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
		echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads        
        echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
		echo "40" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
		echo "1440000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		
        # Configure governor settings for big cluster
        echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif
        echo "50000 1440000:20000" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
        echo 80 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
        echo 50000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
        echo 633600 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        echo "95 633600:75 768000:80 864000:81 960000:81 1248000:85 1344000:85 1440000:85 1536000:85 1632000:86 1824000:87" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
		echo "0" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
        echo 50000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis
        
		# Big cluster hotplugged by core_ctl
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		
		# 40ms input boost @ 600Mhz (only little cluster)
		echo "0:600000 1:600000 2:600000 3:600000 4:0 5:0" > /sys/module/cpu_boost/parameters/input_boost_freq
		echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

		# 367Mhz GPU max speed
		echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
		echo 367000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 3 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
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
		echo "40" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration     
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
		echo "40" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
        echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
        echo 80000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis        

		# Big cluster always on
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		
		# 40ms input boost @ 1.2Ghz
		echo "0:1248000 1:1248000 2:1248000 3:1248000 4:1248000 5:1248000" > /sys/module/cpu_boost/parameters/input_boost_freq
		echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

		# 600Mhz GPU max speed
		echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
		echo 600000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
		echo 5 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 5 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
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
		echo "100" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
        echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
        echo 80000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis        

		# Big cluster always on
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
		echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
		
		# 100ms input boost @ 1.4Ghz / 1.8Ghz
		echo "0:1440000 1:1440000 2:1440000 3:1440000 4:1824000 5:1824000" > /sys/module/cpu_boost/parameters/input_boost_freq
		echo 100 > /sys/module/cpu_boost/parameters/input_boost_ms		

		# 600Mhz GPU min and max speed
		# GPU locked at 600Mhz
		echo "performance" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
		echo 600000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
		echo 600000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
		echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
		echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
		echo 0 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
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

