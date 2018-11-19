#!/bin/bash
set -e
#todo close emulator on error

. ./utils.sh --source-only

INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME="getTestInstrumentationRunnerName"

#todo uncoment
#./gradlew assembleAndroidTest

TMP_PACKAGE_NAME=/data/local/tmp/

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
    gnome-terminal -e "emulator -avd ${avd_name} -skin ${scin_size} -no-snapshot-save"

    sleep 20s
    EMULATOR_NAME=`get_emulator_name`
fi

cd ..
PROJECT_LOCATION="`pwd`/"

for androidTestApk in `get_apk_list "androidTest"`
do
    print ${androidTestApk}

    ANDROID_TEST_APK_FOLDER=`get_apk_folder_names ${androidTestApk}`
    ANDROID_TEST_APK_FILE_NAME=`echo ${androidTestApk} | rev | cut -d '/' -f1 | rev`

    # find debug apk and test package name
    cd ${ANDROID_TEST_APK_FOLDER}
    APK_NAME=`get_apk_list "debug"`

    # check if debug apk exists
    if ! [[ -z ${APK_NAME} ]]; then
        DEBUG_APK_NAME=${ANDROID_TEST_APK_FOLDER}/${APK_NAME}
        cd ..

        TEST_PACKAGE_NAME=`get_package_name_from_apk ${androidTestApk}`
        print ${TEST_PACKAGE_NAME}

        DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
        print ${DEBUG_PACKAGE_NAME}

        CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME=:${ANDROID_TEST_APK_FOLDER}:${INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME}
        CURRENT_INSTRUMENTATION_RUNNER_NAME=`./gradlew ${CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME} | tail -4 | head -1`
        print ${CURRENT_INSTRUMENTATION_RUNNER_NAME}

        DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${DEBUG_PACKAGE_NAME}
        TEST_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${TEST_PACKAGE_NAME}

        push ${EMULATOR_NAME} ${PROJECT_LOCATION}${DEBUG_APK_NAME} ${DEBUG_APK_PACKAGE_NAME}
        install_apk ${EMULATOR_NAME} ${DEBUG_APK_PACKAGE_NAME}

        push ${EMULATOR_NAME} ${PROJECT_LOCATION}${androidTestApk} ${TEST_APK_PACKAGE_NAME}
        install_apk ${EMULATOR_NAME} ${TEST_APK_PACKAGE_NAME}

        run_instrumental_test ${EMULATOR_NAME} ${TEST_PACKAGE_NAME}/${CURRENT_INSTRUMENTATION_RUNNER_NAME}
    else
        cd ..
    fi
    print_line
done
#todo close emulator