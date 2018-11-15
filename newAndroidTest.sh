#!/bin/bash
set -e

. ./utils.sh --source-only

# BUILD APK FOR INSTRUMENTAL TESTS

#todo uncoment
#./gradlew clean assembleDebug assembleAndroidTest

TMP_PACKAGE_NAME=/data/local/tmp/
ANDROID_JUNIT_RUNNER_NAME="androidx.test.runner.AndroidJUnitRunner"

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
    gnome-terminal -e "emulator -avd ${avd_name} -skin ${scin_size} -no-snapshot-save"

    adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

    cd ..
    PROJECT_LOCATION="`pwd`/"
    print "Project location ${PROJECT_LOCATION}"

    print ANDROID_TEST_APK_LIST
    ANDROID_TEST_APK_LIST=`get_apk_list "androidTest" | grep -v sample-common | grep -v sample-dagger`
    print_elements ${ANDROID_TEST_APK_LIST}

    print ANDROID_TEST_APK_FOLDER_NAMES
    ANDROID_TEST_APK_FOLDER_NAMES=`get_apk_folder_names ${ANDROID_TEST_APK_LIST}`
    print_elements ${ANDROID_TEST_APK_FOLDER_NAMES}

    print_line

    for folder in ${ANDROID_TEST_APK_FOLDER_NAMES}
    do
        # find debug apk and test package name
        cd ${folder}
        echo ${folder}

        TEST_PACKAGE_NAME=`get_test_packages_new`
        echo ${TEST_PACKAGE_NAME}

        DEBUG_APK_NAME=${folder}/`get_apk_list "debug"`
        echo ${DEBUG_APK_NAME}

        DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${TEST_PACKAGE_NAME}
        TEST_APK_PACKAGE_NAME=${DEBUG_APK_PACKAGE_NAME}.test

        push "${PROJECT_LOCATION}${DEBUG_APK_NAME}" ${DEBUG_APK_PACKAGE_NAME}
        install_apk ${DEBUG_APK_PACKAGE_NAME}

        push "${PROJECT_LOCATION}${ANDROID_TEST_APK_LIST}" ${TEST_APK_PACKAGE_NAME}
        install_apk ${TEST_APK_PACKAGE_NAME}

        adb shell am instrument -w -r -e debug false ${TEST_PACKAGE_NAME}.test/"$ANDROID_JUNIT_RUNNER_NAME"

        cd ..
    done

    print_line
    #todo close emulator
else
    echo Emulator is running
fi