#!/bin/bash
set -e

. ./utils.sh --source-only

# BUILD APK FOR INSTRUMENTAL TESTS

# Script location: android-standard/ci-shell-scripts
SCRIPT_LOCATION=`pwd`

cd ..
PROJECT_LOCATION="`pwd`/"
print "Project location ${PROJECT_LOCATION}"

#todo uncoment
#./gradlew assembleAndroidTest

print ANDROID_TEST_APK_LIST
ANDROID_TEST_APK_LIST=`get_apk_list "androidTest"`
print_elements ${ANDROID_TEST_APK_LIST}

print DEBUG_APK_LIST
DEBUG_APK_LIST=`get_apk_list "debug"`
print_elements ${DEBUG_APK_LIST}

print ANDROID_TEST_CLASSES
ANDROID_TEST_CLASSES=`find . -name *AndroidTest.kt`
print_elements ${ANDROID_TEST_CLASSES}

print ANDROID_TEST_CLASS_NAME
ANDROID_TEST_CLASS_NAME=`echo ${ANDROID_TEST_CLASSES} | rev | cut -d '/' -f1 | rev | cut -d '.' -f1`
print_elements ${ANDROID_TEST_CLASS_NAME}

print ANDROID_TEST_PACKAGE_NAME
ANDROID_TEST_PACKAGE_NAME=`head -n 1 ${ANDROID_TEST_CLASSES} | cut -d ' ' -f2`
print_elements ${ANDROID_TEST_PACKAGE_NAME}

TMP_PACKAGE_NAME=/data/local/tmp/
ANDROID_JUNIT_RUNNER_NAME="androidx.test.runner.AndroidJUnitRunner"

cd ${SCRIPT_LOCATION}

# check if the emulator is running
EMULATOR_NAME=`get_emulator_name`

if [[ -z "$EMULATOR_NAME" ]]; then
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

    DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${ANDROID_TEST_PACKAGE_NAME}
    TEST_APK_PACKAGE_NAME=${DEBUG_APK_PACKAGE_NAME}.test

    push "${PROJECT_LOCATION}${DEBUG_APK_LIST}" ${DEBUG_APK_PACKAGE_NAME}
    install_apk ${DEBUG_APK_PACKAGE_NAME}

    push "${PROJECT_LOCATION}${ANDROID_TEST_APK_LIST}" ${TEST_APK_PACKAGE_NAME}
    install_apk ${TEST_APK_PACKAGE_NAME}

    adb shell am instrument -w -r -e debug false -e class "${ANDROID_TEST_PACKAGE_NAME}.${ANDROID_TEST_CLASS_NAME}" ${ANDROID_TEST_PACKAGE_NAME}.test/"$ANDROID_JUNIT_RUNNER_NAME"
    #todo close emulator
else
    echo Emulator is running
fi