#!/bin/bash

# build APK for instrumental tests
#todo cd to project directory
#./gradlew assembleAndroidTest
#grep -r --include "*-androidTest.apk" . | cut -d ' ' -f3

# check if the emulator is running
EMULATOR_STATUS=`adb devices | grep emulator | cut -f1`
if [[ -z "$EMULATOR_STATUS" ]]; then
    # read params from config file
    . avd-config
    avdmanager create avd -f -n "$avd_name" -d "$device_name" -k "$sdk_id" -c "$sdcard_size"
    # launch emulator in background process
    # emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save &
    # launch emulator in another terminal tab
    # gnome-terminal -x sh -c "emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save"
    # launch emulator in another terminal window
    gnome-terminal -e "emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save"
    adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'
    adb push /home/volodina/AndroidStudioProjects/android-standard/app-migration-sample/build/outputs/apk/debug/app-migration-sample-debug.apk /data/local/tmp/ru.surfstudio.android.app.migration.sample
    adb shell pm install -t -r "/data/local/tmp/ru.surfstudio.android.app.migration.sample"
    adb push /home/volodina/AndroidStudioProjects/android-standard/app-migration-sample/build/outputs/apk/androidTest/debug/app-migration-sample-debug-androidTest.apk /data/local/tmp/ru.surfstudio.android.app.migration.sample.test
    adb shell pm install -t -r "/data/local/tmp/ru.surfstudio.android.app.migration.sample.test"
    adb shell am instrument -w -r -e debug false -e class 'ru.surfstudio.android.app.migration.sample.AppMigrationSampleTest' ru.surfstudio.android.app.migration.sample.test/androidx.test.runner.AndroidJUnitRunner
    #todo close emulator
else
    echo Emulator is running
fi