#!/bin/bash

ANDROID_MANIFEST_FILE_NAME="AndroidManifest.xml"
INSTRUMENTATION_RUNNER_GRADLE_TASK_NAME="getTestInstrumentationRunnerName"
INSTRUMENTATION_RUNNER_LISTENER_NAME="de.schroepf.androidxmlrunlistener.XmlRunListener"
DEFAULT_TEST_REPORT_FILENAME="report-0.xml"
WAIT_FOR_DEVICE_TIMEOUT=5

is_avd_exists() {
    : '
        Function which checks if emulator with the given name exists
    '
    for avdName in `avdmanager list avd | grep Name | awk '{ print $2 }'`; do
        if [[ ${avdName} == $1 ]]; then
            return 0
        fi
    done
    return 1
}

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

delete_avd() {
    : '
        Function for removing the AVD with given params
    '
    avdmanager delete avd -n "$1" || true
}

launch_emulator() {
    : '
        Function for launching emulator
        $1 - name of AVD which will be launched
        $2 - skin size of AVD
        $3 - flag which shows if emulator needs to save its snapshot state
    '
    # launch emulator in background process
    # emulator -avd "$1" -skin "$2" -no-snapshot-save &

    # launch emulator in another terminal tab
    # gnome-terminal -x sh -c "emulator -avd '$1' -skin '$2' -no-snapshot-save"

    # launch emulator in another terminal window
    if [[ $3 == true ]]; then
        echo "stay"
        xterm -e emulator -avd "$1" -skin "$2" -no-boot-anim &
    else
        echo "not stay"
        xterm -e emulator -avd "$1" -skin "$2" -no-boot-anim -no-snapshot-save &
    fi
}

close_emulator() {
    : '
        Function which closes an emulator with given name
        $1 - emulator name
    '
    adb -s $1 emu kill
    # close all emulators
    # adb devices | grep emulator | cut -f1 | while read line; do adb -s $line emu kill; done
}

wait_for_device() {
    adb -s $1 wait-for-device

    #echo $1 > temp
    #timeout --foreground ${WAIT_FOR_DEVICE_TIMEOUT} bash -c 'adb -s "$(<temp)" wait-for-device'

    #echo $1 | timeout --foreground ${WAIT_FOR_DEVICE_TIMEOUT} sh -c 'echo here $1 here;:'
    #adb -s $1 wait-for-device &

    #echo !!!!!!!!!!!!!!
    #adb -s $1 wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'
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
    # check if APK exists
    TEMP=`adb -s $1 shell pm list packages | grep $2`
    if [[ $? == 0 ]]; then
        echo "uninstall previous app"
        adb -s $1 uninstall $2
    fi
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

get_emulator_status() {
    : '
        Function which returns a status of emulator with given name
    '
    adb devices | grep emulator | cut -f2
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