#!/bin/bash
set -e
#todo close emulator on error

. ./utils.sh --source-only

NULL_INSTRUMENTATION_RUNNER_NAME="null"

OUTPUT_FILENAME="result"

TEST_BUILD_TYPE_NAME="debug"
ANDROID_TEST_APK_SUFFIX="androidTest"
ANDROID_TEST_APK_FILENAME_SUFFIX=-${TEST_BUILD_TYPE_NAME}-${ANDROID_TEST_APK_SUFFIX}.apk

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

for androidTestApk in `get_apk_list ${ANDROID_TEST_APK_SUFFIX}`
do
    print ${androidTestApk}

    ANDROID_TEST_APK_MAIN_FOLDER=`get_apk_folder_names ${androidTestApk}`
    ANDROID_TEST_APK_FILE_NAME=`echo ${androidTestApk} | rev | cut -d '/' -f1 | rev`

    # check if project has submodules
    ANDROID_TEST_APK_MODULE_FOLDER=`echo ${androidTestApk} | cut -d '/' -f2`

    if [[ ${ANDROID_TEST_APK_MODULE_FOLDER} != build ]]; then
        ANDROID_TEST_APK_PREFIX=${ANDROID_TEST_APK_MODULE_FOLDER}
    else
        ANDROID_TEST_APK_PREFIX=`echo ${ANDROID_TEST_APK_FILE_NAME} | awk -F ${ANDROID_TEST_APK_FILENAME_SUFFIX} '{ print $1 }'`
    fi

    if [[ ${ANDROID_TEST_APK_MAIN_FOLDER} != ${ANDROID_TEST_APK_PREFIX} ]]; then
        CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME=`get_instrumentation_runner_name ${ANDROID_TEST_APK_MAIN_FOLDER}:${ANDROID_TEST_APK_PREFIX}`
    else
        CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME=`get_instrumentation_runner_name ${ANDROID_TEST_APK_MAIN_FOLDER}`
    fi

    # find debug apk and test package name
    cd ${ANDROID_TEST_APK_MAIN_FOLDER}
    APK_NAME=`get_apk_list ${TEST_BUILD_TYPE_NAME}`

    # check if debug apk exists
    if ! [[ -z ${APK_NAME} ]]; then
        DEBUG_APK_NAME=${ANDROID_TEST_APK_MAIN_FOLDER}/${APK_NAME}
        cd ..

        ./gradlew ${CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME} > ${OUTPUT_FILENAME}
        CURRENT_INSTRUMENTATION_RUNNER_NAME=`cat ${OUTPUT_FILENAME} | tail -4 | head -1`

        # check if testInstrumentationRunnerName is not null for the current module
        if [[ ${CURRENT_INSTRUMENTATION_RUNNER_NAME} != ${NULL_INSTRUMENTATION_RUNNER_NAME} ]]; then
            TEST_PACKAGE_NAME=`get_package_name_from_apk ${androidTestApk}`
            print ${TEST_PACKAGE_NAME}

            DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
            print ${DEBUG_PACKAGE_NAME}

            print ${CURRENT_INSTRUMENTATION_RUNNER_NAME}

            DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${DEBUG_PACKAGE_NAME}
            TEST_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${TEST_PACKAGE_NAME}

            push ${EMULATOR_NAME} ${PROJECT_LOCATION}${DEBUG_APK_NAME} ${DEBUG_APK_PACKAGE_NAME}
            install_apk ${EMULATOR_NAME} ${DEBUG_APK_PACKAGE_NAME}

            push ${EMULATOR_NAME} ${PROJECT_LOCATION}${androidTestApk} ${TEST_APK_PACKAGE_NAME}
            install_apk ${EMULATOR_NAME} ${TEST_APK_PACKAGE_NAME}

            run_instrumental_test ${EMULATOR_NAME} ${TEST_PACKAGE_NAME}/${CURRENT_INSTRUMENTATION_RUNNER_NAME}
        fi
    else
        cd ..
    fi
    print_line
done
#todo close emulator

rm ${OUTPUT_FILENAME}