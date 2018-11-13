#!/bin/bash

# read params from config file
. avd-config
rm -r /home/volodina/.android/avd/avd-androidTest.* #todo remove
avdmanager create avd -n "$avd_name" -d "$device_name" -k "$sdk_id" -c "$sdcard_size"
emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save