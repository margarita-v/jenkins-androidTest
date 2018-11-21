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

create_avd() {
    : '
        Function for creation the AVD with given params
        $1 - name of the new AVD
        $2 - device name for AVD
        $3 - SDK ID
        $4 - sdcard size
    '
    avdmanager create avd -f -n "$1" -d "$2" -k "$3" -c "$4"
}

launch_emulator() {
    : '
        Function for launching emulator
        $1 - name of AVD which will be launched
        $2 - skin size of AVD
    '
    # launch emulator in background process
    # emulator -avd "$1" -skin "$2" -no-snapshot-save &

    # launch emulator in another terminal tab
    # gnome-terminal -x sh -c "emulator -avd '$1' -skin '$2' -no-snapshot-save"

    # launch emulator in another terminal window
    gnome-terminal -e "emulator -avd '$1' -skin '$2' -no-snapshot-save"
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
        for a concrete module which package name is passed as parameter
    '
    echo "/sdcard/Android/data/$1/files/$DEFAULT_TEST_REPORT_FILENAME"
}

pull_test_report() {
    : '
        Function for pulling the test report file from emulator
        $1 - emulator name
        $2 - package name of module which is a part of the test report file name
        $3 - output file name for local file which will contain the test report
    '
    TEST_REPORT_FILENAME=`get_test_report_filename $2`
    if [[ `adb -s $1 shell ls ${TEST_REPORT_FILENAME} 2> /dev/null` ]]; then
        adb -s $1 shell cat ${TEST_REPORT_FILENAME}  > $3
    fi
}

install_apk() {
    : '
        Function which installs the APK to emulator
        $1 - emulator name
        $2 - APK package name
    '
    adb -s $1 shell pm install -t -r $2
}

uninstall_apk() {
    : '
        Function for uninstalling the APK from emulator
        $1 - emulator name
        $2 - APK package name
    '
    echo uninstall previous app
    adb -s $1 uninstall $2
}

run_instrumental_test() {
    : '
        Function for launching an instrumental tests on the emulator
        $1 - emulator name
        $2 - test.package.name/AndroidInstrumentalRunnerName
    '
    adb -s $1 shell am instrument -w -r -e debug false -e listener ${INSTRUMENTATION_RUNNER_LISTENER_NAME} $2
}

get_emulator_name() {
    : '
        Function which returns a name of the first emulator in the adb devices list
    '
    adb devices | grep emulator | cut -f1
}

get_apk_folder_name() {
    : '
        Function which returns a folder name for the APK file
        $1 - APK file name
    '
    echo $1 | cut -d '/' -f1
}

get_package_name_from_apk() {
    : '
        Function which returns a package name from the APK file
        $1 - APK file name
    '
    # Read AndroidManifest directly from APK file
    aapt dump xmltree $1 ${ANDROID_MANIFEST_FILE_NAME} | grep package | cut -d '"' -f2
}

get_length() {
    echo $1 | wc -m
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