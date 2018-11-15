#!/bin/bash

ANDROID_MANIFEST_FILE_NAME="AndroidManifest.xml"

get_apk_list() {
    : '
        Функция, возвращающая список имен APK-файлов с заданным суффиксом,
        который передается параметром.
    '
    grep -r --include "*-$1.apk" . | cut -d ' ' -f3 | grep sample
}

print_line() {
    echo _____________________________________________________________________
    echo
}

print_elements() {
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

push() {
    adb push $1 $2
}

install_apk() {
    adb shell pm install -t -r $1
}

get_emulator_name() {
    return `adb devices | grep emulator | cut -f1`
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
        RESULT+=`echo ${word} | grep -v sample.common | grep -v sample.dagger | cut -d '/' -f1`
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