#!/bin/bash
set -e

. ./utils.sh --source-only

NULL_INSTRUMENTATION_RUNNER_NAME="null"

OUTPUT_FILENAME="result"

TEST_BUILD_TYPE_NAME="debug"
ANDROID_TEST_APK_SUFFIX="androidTest"
ANDROID_TEST_APK_FILENAME_SUFFIX=-${TEST_BUILD_TYPE_NAME}-${ANDROID_TEST_APK_SUFFIX}.apk

cd ..

#./gradlew clean assembleDebug assembleAndroidTest

for androidTestApk in `get_apk_list ${ANDROID_TEST_APK_SUFFIX}`
do
    echo ${androidTestApk}

    ANDROID_TEST_APK_MAIN_FOLDER=`get_apk_folder_name ${androidTestApk}`
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
            echo ${TEST_PACKAGE_NAME}

            DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
            echo ${DEBUG_PACKAGE_NAME}

            echo ${CURRENT_INSTRUMENTATION_RUNNER_NAME}
        fi
    else
        cd ..
    fi
    print_line
done

rm ${OUTPUT_FILENAME}