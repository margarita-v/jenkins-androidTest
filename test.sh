#!/bin/bash
set -e

: '
    Функция, возвращающая список имен APK-файлов с заданным суффиксом,
    который передается параметром.
'
get_apk_list() {
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

cd ..

print ANDROID_TEST_APK_LIST
ANDROID_TEST_APK_LIST=`get_apk_list "androidTest"`
print_elements ${ANDROID_TEST_APK_LIST}

print DEBUG_APK_LIST
DEBUG_APK_LIST=`get_apk_list "debug"`
print_elements ${DEBUG_APK_LIST}

print ANDROID_TEST_CLASSES
ANDROID_TEST_CLASSES=`find . -name "*AndroidTest.kt"`
print_elements ${ANDROID_TEST_CLASSES}

print ANDROID_TEST_CLASS_NAMES
ANDROID_TEST_CLASS_NAMES=`get_class_names ${ANDROID_TEST_CLASSES}`
print_elements ${ANDROID_TEST_CLASS_NAMES}

print ANDROID_TEST_PACKAGES
ANDROID_TEST_PACKAGES=`get_test_packages ${ANDROID_TEST_CLASSES}`
print_elements ${ANDROID_TEST_PACKAGES}