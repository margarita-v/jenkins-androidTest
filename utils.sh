#!/bin/bash

ANDROID_MANIFEST_FILE_NAME="AndroidManifest.xml"
INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME="getTestInstrumentationRunnerName"
INSTRUMENTATION_RUNNER_LISTENER_NAME="de.schroepf.androidxmlrunlistener.XmlRunListener"
DEFAULT_TEST_REPORT_FILENAME="report-0.xml"

get_apk_list() {
    : '
        Function which returns a list of APK files with a concrete suffix,
        which is passed as parameter
    '
    grep -r --include "*-$1.apk" . | cut -d ' ' -f3
}

get_instrumentation_runner_name() {
    : '
        Function which returns a name of gradle task for getting of instrumentation runner name
        for a concrete module which name is passed as parameter
    '
    echo :$1:${INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME}
}

print_line() {
    echo _____________________________________________________________________
    echo
}

print_elements() {
    : '
        Function which prints all elements of list and its size
    '
    print_line
    for word in $@
    do
        echo ${word}
    done
    echo
    SIZE=`echo $@ | wc -w`
    echo ${SIZE} elements
    print_line
}

print() {
    echo
    echo $1
    echo
}

wait_for_device() {
    adb -s $1 wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'
}

clean_app_data() {
    : '
        Function which removes all package data for a concrete emulator
        $1 - emulator name
        $2 - package name
    '
    adb -s $1 shell pm clear $2
}

push() {
    : '
        Function for pushing APK to the concrete apk package
        $1 - emulator name
        $2 - APK name
        $3 - APK dest package
    '
    adb -s $1 push $2 $3
}

get_test_report_filename() {
    : '
        Function which returns a test report filename
        for a concrete module which name is passed as parameter
    '
    echo "/sdcard/Android/data/$1/files/$DEFAULT_TEST_REPORT_FILENAME"
}

pull_test_report() {
    TEST_REPORT_FILENAME=`get_test_report_filename $2`
    if [[ `adb -s $1 shell ls ${TEST_REPORT_FILENAME} 2> /dev/null` ]]; then
        adb -s $1 shell cat ${TEST_REPORT_FILENAME}  > $3
    fi
}

install_apk() {
    adb -s $1 shell pm install -t -r $2
}

run_instrumental_test() {
    adb -s $1 shell am instrument -w -r -e debug false -e listener ${INSTRUMENTATION_RUNNER_LISTENER_NAME} $2
}

get_emulator_name() {
    adb devices | grep emulator | cut -f1
}

get_class_names() {
    RESULT=""
    for word in $@
    do
        RESULT+=`echo ${word} | rev | cut -d '/' -f1 | rev | cut -d '.' -f1`
        RESULT+=' '
    done
    echo ${RESULT}
}

get_test_packages() {
    RESULT=""
    for word in $@
    do
        RESULT+=`head -n 1 ${word} | cut -d ' ' -f2`
        RESULT+=' '
    done
    echo ${RESULT}
}

get_manifests() {
    find . -name "*${ANDROID_MANIFEST_FILE_NAME}" | grep "src/main/${ANDROID_MANIFEST_FILE_NAME}$"
}

get_test_packages_new() {
    get_manifests | xargs cat | grep "package=" | cut -d '"' -f2
}

get_manifest_suffix_length() {
    echo ${ANDROID_MANIFEST_FILE_NAME} | wc -m
}

get_manifests_folders_names() {
    INPUT=`get_manifests | grep sample | grep -v sample-common | grep -v sample-dagger | cut -c 3-`
    RESULT=""
    LENGTH=`get_manifest_suffix_length`
    for word in ${INPUT}
    do
        RESULT+=${word::-${LENGTH}}
        RESULT+=' '
    done
    echo ${RESULT}
}

get_apk_folder_names() {
    RESULT=""
    for word in $@
    do
        RESULT+=`echo ${word} | cut -d '/' -f1`
        RESULT+=' '
    done
    echo ${RESULT}
}

get_test_packages_for_apks() {
    RESULT=""
    for word in $@
    do
        cd ${word}
        RESULT+=`get_test_packages_new`
        RESULT+=' '
        cd ..
    done
    echo ${RESULT}
}

get_debug_apks() {
    RESULT=""
    for word in $@
    do
        cd ${word}
        RESULT+=`get_apk_list "debug"`
        RESULT+=' '
        cd ..
    done
    echo ${RESULT}
}

get_length() {
    echo $1 | wc -m
}

get_package_name_from_apk() {
    aapt dump xmltree $1 ${ANDROID_MANIFEST_FILE_NAME} | grep package | cut -d '"' -f2
}