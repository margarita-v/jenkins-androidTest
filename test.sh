#!/bin/bash
set -e

. ./utils.sh --source-only

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