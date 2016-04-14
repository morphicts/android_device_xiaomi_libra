Device configuration for Xiaomi Mi-4c.
=====================================

www.teamsuperluminal.org

# Needed packages (ubuntu 15.x)
sudo apt-get install bison build-essential curl flex git gnupg gperf libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev libxml2 libxml2-utils lzop maven openjdk-7-jdk openjdk-7-jre pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev realpath

# Init repo
repo init -u git://github.com/CyanogenMod/android.git -b stable/cm-13.0-ZNH2K

# Sync
repo sync -j4

# Copy device/xiaomi/libra/local_manifests/libra.xml to $ANDROID_BUILD_TOP/.repo/local_manifests/
cp ./device/xiaomi/libra/local_manifests/libra.xml $ANDROID_BUILD_TOP/.repo/local_manifests/

# Sync
repo sync -j4 

# Force sync's
repo sync --force-sync bootable/recovery
repo sync --force-sync external/jpeg
repo sync --force-sync frameworks/base
repo sync --force-sync frameworks/native

# Sync repo
repo sync -j4 

# Build
lunch cm_libra-userdebug
brunch cm_libra-userdebug

