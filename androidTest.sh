#!/bin/bash
set -e

# register actions which must be performed on any errors
trap cleanup_on_exit 1 2 3 6

cleanup_on_exit() {
    close_running_emulator
    remove_report_files
}

create_and_launch_new_emulator() {
    echo "create new emulator"
    create_avd "$avd_name" "$device_name" "$sdk_id" "$sdcard_size"
    launch_concrete_emulator
}

launch_concrete_emulator() {
    launch_emulator "$avd_name" "$skin_size" "$stay"
}

remove_report_files() {
    rm -rf */report*
    rm -rf template/*/report*
    rm ${GRADLE_OUTPUT_FILENAME} 2> /dev/null || true
}

close_running_emulator() {
    # close running emulator if it exists
    CURRENT_EMULATOR_NAME=`get_emulator_name`
    if ! [[ -z ${CURRENT_EMULATOR_NAME} ]]; then
        echo "close running emulator"
        close_emulator ${CURRENT_EMULATOR_NAME}
    fi
    # delete AVD if needed
    if [[ ${stay} == false ]]; then
        echo "delete avd"
        delete_avd ${avd_name}
    fi
}

. ./utils.sh --source-only

# name of undefined instrumentation runner for module
NULL_INSTRUMENTATION_RUNNER_NAME="null"

# name of temporary file for output of gradle task
GRADLE_OUTPUT_FILENAME="result"

# name of build type which is used for running tests
TEST_BUILD_TYPE_NAME="debug"

# suffixes of APK files
ANDROID_TEST_APK_SUFFIX="androidTest"
ANDROID_TEST_APK_FILENAME_SUFFIX=-${TEST_BUILD_TYPE_NAME}-${ANDROID_TEST_APK_SUFFIX}.apk

# package name of temporary dir of emulator
TMP_PACKAGE_NAME="/data/local/tmp/"

# timeout which is used for creation of emulator
LONG_TIMEOUT_SEC=20
# timeout which is used for launching of reused emulator
SMALL_TIMEOUT_SEC=7

SHELL_SCRIPTS_DIR=`pwd`
# move to project root dir for building
cd ..
PROJECT_ROOT_DIR=`pwd`/

echo "assemble APK files for instrumental tests"
./gradlew assembleAndroidTest

 # read params from config file
. ${SHELL_SCRIPTS_DIR}/avd-config

CURRENT_TIMEOUT_SEC=${LONG_TIMEOUT_SEC}
EMULATOR_NAME=`get_emulator_name`

if [[ ${reuse} == true ]]; then
    # check if emulator exists
    is_avd_exists "$avd_name" && EXIT_CODE=$? || true 2> /dev/null
    if [[ ${EXIT_CODE} == 0 ]]; then
        echo "launch reused emulator"
        # check if emulator is running
        if [[ -z ${EMULATOR_NAME} ]]; then
            CURRENT_TIMEOUT_SEC=${SMALL_TIMEOUT_SEC}
            launch_concrete_emulator
        else
            CURRENT_TIMEOUT_SEC=0
            echo "emulator have been launched already"
        fi
    else
        create_and_launch_new_emulator
    fi
else
    close_running_emulator
    create_and_launch_new_emulator
fi

echo "waiting ${CURRENT_TIMEOUT_SEC} seconds..."
sleep ${CURRENT_TIMEOUT_SEC}

#echo "wait for device"
#wait_for_device ${EMULATOR_NAME}

EMULATOR_NAME=`get_emulator_name`
EMULATOR_STATUS=`get_emulator_status`
adb devices

if [[ ${EMULATOR_STATUS} == "offline" || -z ${EMULATOR_NAME} ]]; then
    echo "emulator is offline"
    close_running_emulator
    create_and_launch_new_emulator
    echo "waiting ${LONG_TIMEOUT_SEC} seconds..."
    sleep ${LONG_TIMEOUT_SEC}
fi

echo "start running tests"

for androidTestApk in `get_apk_list ${ANDROID_TEST_APK_SUFFIX}`; do
    print ${androidTestApk}

    ANDROID_TEST_APK_MAIN_FOLDER=`get_apk_folder_name ${androidTestApk}`
    ANDROID_TEST_APK_FILE_NAME=`echo ${androidTestApk} | rev | cut -d '/' -f1 | rev`

    # check if project has submodules
    ANDROID_TEST_APK_MODULE_FOLDER=`echo ${androidTestApk} | cut -d '/' -f2`

    if [[ ${ANDROID_TEST_APK_MODULE_FOLDER} != build ]]; then
        ANDROID_TEST_APK_PREFIX=${ANDROID_TEST_APK_MODULE_FOLDER}
    else
        ANDROID_TEST_APK_PREFIX=`echo ${ANDROID_TEST_APK_FILE_NAME} \
            | awk -F ${ANDROID_TEST_APK_FILENAME_SUFFIX} '{ print $1 }'`
    fi

    TEST_REPORT_FOLDER=${ANDROID_TEST_APK_MAIN_FOLDER}
    TEST_REPORT_FILENAME_SUFFIX=${ANDROID_TEST_APK_MAIN_FOLDER}

    if [[ ${ANDROID_TEST_APK_MAIN_FOLDER} != ${ANDROID_TEST_APK_PREFIX} ]]; then
        CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME=`get_instrumentation_runner_name \
            ${ANDROID_TEST_APK_MAIN_FOLDER}:${ANDROID_TEST_APK_PREFIX}`
        TEST_REPORT_FILENAME_SUFFIX+="-$ANDROID_TEST_APK_PREFIX"
        TEST_REPORT_FOLDER+="/$ANDROID_TEST_APK_PREFIX"
    else
        CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME=`get_instrumentation_runner_name \
            ${ANDROID_TEST_APK_MAIN_FOLDER}`
    fi

    # find debug apk and test package name
    cd ${ANDROID_TEST_APK_MAIN_FOLDER}
    APK_NAME=`get_apk_list ${TEST_BUILD_TYPE_NAME}`

    # check if debug apk exists
    if ! [[ -z ${APK_NAME} ]]; then
        DEBUG_APK_NAME=${ANDROID_TEST_APK_MAIN_FOLDER}/${APK_NAME}
        cd ..

        ./gradlew ${CURRENT_INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME} > ${GRADLE_OUTPUT_FILENAME}
        CURRENT_INSTRUMENTATION_RUNNER_NAME=`cat ${GRADLE_OUTPUT_FILENAME} | tail -4 | head -1`

        # check if testInstrumentationRunnerName is not null for the current module
        if [[ ${CURRENT_INSTRUMENTATION_RUNNER_NAME} != ${NULL_INSTRUMENTATION_RUNNER_NAME} ]]; then
            print ${CURRENT_INSTRUMENTATION_RUNNER_NAME}

            TEST_PACKAGE_NAME=`get_package_name_from_apk ${androidTestApk}`
            print ${TEST_PACKAGE_NAME}

            DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
            print ${DEBUG_PACKAGE_NAME}

            # clear all app data for previous tests
            if [[ ${reuse} == true ]]; then
                # ignore error result code for grep
                uninstall_apk ${EMULATOR_NAME} ${DEBUG_PACKAGE_NAME} || true
            fi

            DEBUG_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${DEBUG_PACKAGE_NAME}
            TEST_APK_PACKAGE_NAME=${TMP_PACKAGE_NAME}${TEST_PACKAGE_NAME}

            push ${EMULATOR_NAME} ${PROJECT_ROOT_DIR}${DEBUG_APK_NAME} ${DEBUG_APK_PACKAGE_NAME}
            install_apk ${EMULATOR_NAME} ${DEBUG_APK_PACKAGE_NAME}

            push ${EMULATOR_NAME} ${PROJECT_ROOT_DIR}${androidTestApk} ${TEST_APK_PACKAGE_NAME}
            install_apk ${EMULATOR_NAME} ${TEST_APK_PACKAGE_NAME}

            run_instrumental_test ${EMULATOR_NAME} ${TEST_PACKAGE_NAME}/${CURRENT_INSTRUMENTATION_RUNNER_NAME}
            pull_test_report ${EMULATOR_NAME} ${DEBUG_PACKAGE_NAME} \
                "$TEST_REPORT_FOLDER/report-$TEST_REPORT_FILENAME_SUFFIX.xml"
        fi
    else
        cd ..
    fi
    print_line
done

close_running_emulator

rm ${GRADLE_OUTPUT_FILENAME}

#todo temporary using
print_results() {
    cat */report* | grep "$1" && cat template/*/report* | grep "$1"
    print_line
}

print_results "<testcase name="
print_results "failures="

remove_report_files