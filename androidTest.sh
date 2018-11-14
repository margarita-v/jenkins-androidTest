#!/bin/bash
set -e

: '
    Функция, возвращающая список имен APK-файлов с заданным суффиксом,
    который передается параметром.
'
get_apk_list() {
    grep -r --include "*-$1.apk" . | cut -d ' ' -f3
}

print() {
    echo $1
    echo
    echo
}

push() {
    adb push $1 $2
}

install_apk() {
    adb shell pm install -t -r $1
}

# BUILD APK FOR INSTRUMENTAL TESTS

# Script location: android-standard/ci-shell-scripts
cd ..
#./gradlew assembleAndroidTest

ANDROID_TEST_APK_LIST=`get_apk_list "androidTest"`
print ${ANDROID_TEST_APK_LIST}

DEBUG_APK_LIST=`get_apk_list "debug"`
print ${DEBUG_APK_LIST}

ANDROID_TEST_CLASSES=`find . -name *AndroidTest.kt`
print ${ANDROID_TEST_CLASSES}

ANDROID_TEST_CLASS_NAME=`echo ${ANDROID_TEST_CLASSES} | rev | cut -d '/' -f1 | rev | cut -d '.' -f1`
print ${ANDROID_TEST_CLASS_NAME}

ANDROID_TEST_PACKAGE_NAME=`head -n 1 ${ANDROID_TEST_CLASSES} | cut -d ' ' -f2`
print ${ANDROID_TEST_PACKAGE_NAME}

TMP_PACKAGE_NAME=/data/local/tmp/
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

    APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${ANDROID_TEST_PACKAGE_NAME}
    TEST_APK_PACKAGE_NAME=${APK_PACKAGE_NAME}.test

    push ${DEBUG_APK_LIST} ${APK_PACKAGE_NAME}
    install_apk ${APK_PACKAGE_NAME}

    push ${ANDROID_TEST_APK_LIST} ${TEST_APK_PACKAGE_NAME}
    install_apk ${TEST_APK_PACKAGE_NAME}

    adb shell am instrument -w -r -e debug false -e class "${ANDROID_TEST_PACKAGE_NAME}.${ANDROID_TEST_CLASS_NAME}" ${ANDROID_TEST_PACKAGE_NAME}.test/"$ANDROID_JUNIT_RUNNER_NAME"
    #todo close emulator
else
    echo Emulator is running
fi