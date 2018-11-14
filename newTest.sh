#!/bin/bash

. ./utils.sh --source-only

cd ..

#./gradlew clean assembleDebug assembleAndroidTest

#print ANDROID_TEST_PACKAGES
#ANDROID_TEST_PACKAGES=`get_test_packages_new | grep -v sample.common | grep -v sample.dagger`
#print_elements ${ANDROID_TEST_PACKAGES}

print ANDROID_TEST_APK_LIST
ANDROID_TEST_APK_LIST=`get_apk_list "androidTest" | grep -v sample-common | grep -v sample-dagger`
print_elements ${ANDROID_TEST_APK_LIST}

print ANDROID_TEST_APK_FOLDER_NAMES
ANDROID_TEST_APK_FOLDER_NAMES=`get_apk_folder_names ${ANDROID_TEST_APK_LIST}`
print_elements ${ANDROID_TEST_APK_FOLDER_NAMES}

print ANDROID_TEST_PACKAGES
ANDROID_TEST_PACKAGES=`get_test_packages_for_apks ${ANDROID_TEST_APK_FOLDER_NAMES}`
print_elements ${ANDROID_TEST_PACKAGES}

print DEBUG_APK_LIST
DEBUG_APK_LIST=`get_apk_list "debug" | grep -v sample-common | grep -v sample-dagger`
print_elements ${DEBUG_APK_LIST}

#print_elements `get_apk_folder_names ${DEBUG_APK_LIST}`


#print ANDROID_MANIFEST_FOLDER_NAMES
#ANDROID_MANIFEST_FOLDER_NAMES=`get_manifests_folders_names`
#print_elements ${ANDROID_MANIFEST_FOLDER_NAMES}

#adb -s FCAZCY04P910 shell am instrument -w -r -e debug false \
#\ "ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner"

#adb -s emulator-5554 shell am instrument -w -r -e debug false \
#\ -e class 'ru.surfstudio.android.custom_scope_sample.AnotherScopeSampleAndroidTest' \
#\ ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner