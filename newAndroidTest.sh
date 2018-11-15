#!/bin/bash
set -e
#todo close emulator on error

. ./utils.sh --source-only

# BUILD APK FOR INSTRUMENTAL TESTS

#todo uncoment
#./gradlew assembleAndroidTest

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

    ANDROID_TEST_APK_LIST=`get_apk_list "androidTest" | grep -v sample-dagger | grep -v sample-common`

    for androidTestApk in ${ANDROID_TEST_APK_LIST}
    do
        print ${androidTestApk}

        ANDROID_TEST_APK_FOLDER=`get_apk_folder_names ${androidTestApk}`
        ANDROID_TEST_APK_FILE_NAME=`echo ${androidTestApk} | rev | cut -d '/' -f1 | rev`

        # find debug apk and test package name
        cd ${ANDROID_TEST_APK_FOLDER}
        #todo find all debug apks which are started with ANDROID_TEST_APK_FOLDER
        DEBUG_APK_NAME=${ANDROID_TEST_APK_FOLDER}/`get_apk_list "debug"`
        cd ..

        TEST_PACKAGE_NAME=`get_package_name_from_apk ${androidTestApk}`
        print ${TEST_PACKAGE_NAME}

        DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
        print ${DEBUG_PACKAGE_NAME}

        DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${DEBUG_PACKAGE_NAME}
        TEST_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${TEST_PACKAGE_NAME}

        push "${PROJECT_LOCATION}${DEBUG_APK_NAME}" ${DEBUG_APK_PACKAGE_NAME}
        install_apk ${DEBUG_APK_PACKAGE_NAME}

        push "${PROJECT_LOCATION}${androidTestApk}" ${TEST_APK_PACKAGE_NAME}
        install_apk ${TEST_APK_PACKAGE_NAME}

        adb shell am instrument -w -r -e debug false ${TEST_PACKAGE_NAME}/"$ANDROID_JUNIT_RUNNER_NAME"

        print_line
    done
    #todo close emulator
else
    echo Emulator is running
fi