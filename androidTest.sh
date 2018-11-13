#!/bin/bash

'''
    Функция, возвращающая список имен APK-файлов с заданным суффиксом,
    который передается параметром.
'''
get_apk_list() {
    grep -r --include "*-$1.apk" . | cut -d ' ' -f3
}

print() {
    echo $1
    echo
    echo
    echo
}

push() {
    adb push $1 $2
}

install_apk() {
    adb shell pm install -t -r $1
}

# build APK for instrumental tests
#todo cd to project directory
#./gradlew assembleAndroidTest
#ANDROID_TEST_APK_LIST=`get_apk_list "androidTest"`
#print $ANDROID_TEST_APK_LIST
#DEBUG_APK_LIST=`get_apk_list "debug"`
#print $DEBUG_APK_LIST

ANDROID_JUNIT_RUNNER_NAME="androidx.test.runner.AndroidJUnitRunner"

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
    #todo add `adb -s $name shell ...`
    gnome-terminal -e "emulator -avd "$avd_name" -skin "$scin_size" -no-snapshot-save"
    adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

    #todo try to change /data/local/tmp/... to custom package
    push /home/volodina/AndroidStudioProjects/android-standard/app-migration-sample/build/outputs/apk/debug/app-migration-sample-debug.apk /data/local/tmp/ru.surfstudio.android.app.migration.sample
    install_apk "/data/local/tmp/ru.surfstudio.android.app.migration.sample"

    push /home/volodina/AndroidStudioProjects/android-standard/app-migration-sample/build/outputs/apk/androidTest/debug/app-migration-sample-debug-androidTest.apk /data/local/tmp/ru.surfstudio.android.app.migration.sample.test
    install_apk "/data/local/tmp/ru.surfstudio.android.app.migration.sample.test"

    adb shell am instrument -w -r -e debug false -e class 'ru.surfstudio.android.app.migration.sample.AppMigrationSampleTest' ru.surfstudio.android.app.migration.sample.test/"$ANDROID_JUNIT_RUNNER_NAME"
    #todo close emulator
else
    echo Emulator is running
fi