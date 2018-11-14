#!/bin/bash

get_apk_list() {
    : '
        Функция, возвращающая список имен APK-файлов с заданным суффиксом,
        который передается параметром.
    '
    grep -r --include "*-$1.apk" . | cut -d ' ' -f3
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
    ANDROID_MANIFEST_FILE_NAME="AndroidManifest.xml"
    find . -name "*${ANDROID_MANIFEST_FILE_NAME}" | grep "src/main/${ANDROID_MANIFEST_FILE_NAME}$"
}

get_test_packages_new() {
    #todo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #todo remove checking for template
    #todo remove checking for samples
    get_manifests | grep -v template | grep sample | xargs cat | grep "package=" | cut -d '"' -f2
}