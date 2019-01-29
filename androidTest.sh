#!/bin/bash
#set -e

# register actions which must be performed on any errors
trap cleanup_on_exit 1 2 3 6

cleanup_on_exit() {
    close_running_emulator
}

create_and_launch_new_emulator() {
    echo "create new emulator"
    create_avd "$avd_name" "$device_name" "$sdk_id" "$sdcard_size"
    launch_concrete_emulator
}

launch_concrete_emulator() {
    launch_emulator "$avd_name" "$skin_size" "$stay"
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

# name of build type which is used for running tests
TEST_BUILD_TYPE_NAME="debug"

# suffixes of APK files
ANDROID_TEST_APK_SUFFIX="androidTest"
ANDROID_TEST_APK_FILENAME_SUFFIX=-${TEST_BUILD_TYPE_NAME}-${ANDROID_TEST_APK_SUFFIX}.apk

SPOON_JAR_NAME="spoon-runner-1.7.1-jar-with-dependencies.jar"

# timeout which is used for creation of emulator
LONG_TIMEOUT_SEC=15
# timeout which is used for launching of reused emulator
SMALL_TIMEOUT_SEC=5
# timeout for execution per test (in seconds)
TIMEOUT_PER_TEST=60

SHELL_SCRIPTS_DIR=`pwd`
# move to project root dir for building
cd ..
PROJECT_ROOT_DIR=`pwd`/

echo "assemble APK files for instrumental tests"
echo ${PROJECT_ROOT_DIR}
#./gradlew assembleAndroidTest

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
    EMULATOR_NAME=`get_emulator_name`
fi

echo "disable animations"
disable_animations ${EMULATOR_NAME}

echo "start running tests"

FAILED_TESTS=""

for androidTestApk in `get_apk_list ${TEST_BUILD_TYPE_NAME}-${ANDROID_TEST_APK_SUFFIX}`; do
    print ${androidTestApk}
    APK_MAIN_FOLDER=`get_apk_folder_name ${androidTestApk}`

    APK_MODULE_NAME=`echo ${androidTestApk} | cut -d '/' -f2`
    APK_PREFIX=${APK_MAIN_FOLDER}
    TEST_REPORT_FILE_NAME_SUFFIX=${APK_MAIN_FOLDER}

    if ! [[ ${APK_MODULE_NAME} == "build" ]]; then
        APK_PREFIX=${APK_MODULE_NAME}
    else
        APK_PREFIX=${APK_MAIN_FOLDER}
    fi

    GRADLE_TASK_PREFIX=${APK_MAIN_FOLDER}

    if ! [[ ${APK_MAIN_FOLDER} == ${APK_PREFIX} ]]; then
        GRADLE_TASK_PREFIX=${APK_MAIN_FOLDER}:${APK_PREFIX}
        TEST_REPORT_FILE_NAME_SUFFIX=${TEST_REPORT_FILE_NAME_SUFFIX}-${APK_PREFIX}
    fi

    # find debug apk and test package name

    APK_NAME=`find ${APK_MAIN_FOLDER} -name "*-${TEST_BUILD_TYPE_NAME}*.apk" \
        ! -name "*-unsigned.apk" ! -name "*-${ANDROID_TEST_APK_SUFFIX}.apk"`

    # check if debug apk exists
    if ! [[ -z ${APK_NAME} ]]; then
        echo ${APK_NAME}

        CURRENT_INSTRUMENTATION_RUNNER_NAME=`./gradlew ":${GRADLE_TASK_PREFIX}:printTestInstrumentationRunnerName" | tail -4 | head -1`

        if ! [[ ${CURRENT_INSTRUMENTATION_RUNNER_NAME} == "null" ]]; then
            echo ${CURRENT_INSTRUMENTATION_RUNNER_NAME}

            SPOON_OUTPUT_DIR="${PROJECT_ROOT_DIR}/${TEST_REPORT_FILE_NAME_SUFFIX}/spoon-output"
            mkdir -p ${SPOON_OUTPUT_DIR}

            # clear all app data for previous tests
            if [[ ${reuse} == true ]]; then
                DEBUG_APK_NAME=${APK_MAIN_FOLDER}/${APK_NAME}
                DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
                echo ${DEBUG_PACKAGE_NAME}

                # ignore error result code for grep
                uninstall_apk ${EMULATOR_NAME} ${DEBUG_PACKAGE_NAME} || true
            fi

            java -jar ${SPOON_JAR_NAME} \
                --apk ${PROJECT_ROOT_DIR}${APK_NAME} \
                --test-apk ${PROJECT_ROOT_DIR}${androidTestApk} \
                --output ${SPOON_OUTPUT_DIR} \
                --adb-timeout ${TIMEOUT_PER_TEST} \
                --debug --fail-on-failure --grant-all \
                -serial ${EMULATOR_NAME}

            if ! [[ $? == 0 ]]; then
                FAILED_TESTS="${FAILED_TESTS} ${APK_MAIN_FOLDER}"
            fi
        fi
    fi
    print_line
done

if [[ -z ${FAILED_TESTS} ]]; then
    echo "all tests passed"
else
    echo ${FAILED_TESTS}
fi

close_running_emulator