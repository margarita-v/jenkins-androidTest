#!/bin/bash

# check if the emulator is running
EMULATOR_STATUS=`adb devices | grep emulator | cut -f1`
if [[ -z "$EMULATOR_STATUS" ]]; then
    # read params from config file
    . avd-config
    avdmanager create avd -f -n "$avd_name" -d "$device_name" -k "$sdk_id" -c "$sdcard_size"
    # launch emulator in background process
    # emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save &
    # launch emulator in another terminal tab
    #gnome-terminal -x sh -c "emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save"
    # launch emulator in another terminal window
    gnome-terminal -e "emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save"
    adb wait-for-device
    echo yes
else
    echo Emulator is running
fi