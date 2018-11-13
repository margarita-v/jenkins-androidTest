#!/bin/bash

# check if the emulator is running
EMULATOR_STATUS=`adb devices | grep emulator | cut -f1`
if [[ -z "$EMULATOR_STATUS" ]]; then
    # read params from config file
    . avd-config
    rm -r /home/volodina/.android/avd/avd-androidTest.* #todo remove
    avdmanager create avd -f -n "$avd_name" -d "$device_name" -k "$sdk_id" -c "$sdcard_size"
    emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save
else
    echo Emulator is running
fi