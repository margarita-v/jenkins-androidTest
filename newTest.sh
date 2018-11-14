#!/bin/bash
set -e

. ./utils.sh --source-only

cd ..

./gradlew clean assembleDebug assembleAndroidTest

print ANDROID_TEST_PACKAGES
ANDROID_TEST_PACKAGES=`get_test_packages_new`
print_elements ${ANDROID_TEST_PACKAGES}

print ANDROID_TEST_APK_LIST
ANDROID_TEST_APK_LIST=`get_apk_list "androidTest" | grep -v template`
print_elements ${ANDROID_TEST_APK_LIST}

print DEBUG_APK_LIST
DEBUG_APK_LIST=`get_apk_list "debug" | grep -v template`
print_elements ${DEBUG_APK_LIST}

#adb -s FCAZCY04P910 shell am instrument -w -r -e debug false \
#\ "ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner"

#adb -s emulator-5554 shell am instrument -w -r -e debug false \
#\ -e class 'ru.surfstudio.android.custom_scope_sample.AnotherScopeSampleAndroidTest' \
#\ ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner