#!/bin/bash

. ./utils.sh --source-only

cd ..

#./gradlew clean assembleDebug assembleAndroidTest

for androidTestApk in `get_apk_list "androidTest"`
do
    echo ${androidTestApk}

    ANDROID_TEST_APK_FOLDER=`get_apk_folder_names ${androidTestApk}`
    ANDROID_TEST_APK_FILE_NAME=`echo ${androidTestApk} | rev | cut -d '/' -f1 | rev`

    # find debug apk and test package name
    cd ${ANDROID_TEST_APK_FOLDER}

    APK_NAME=`get_apk_list "debug"`

    # check if debug apk exists
    if ! [[ -z ${APK_NAME} ]]; then
        DEBUG_APK_NAME=${ANDROID_TEST_APK_FOLDER}/${APK_NAME}
        cd ..

        TEST_PACKAGE_NAME=`get_package_name_from_apk ${androidTestApk}`
        echo ${TEST_PACKAGE_NAME}

        DEBUG_PACKAGE_NAME=`get_package_name_from_apk ${DEBUG_APK_NAME}`
        echo ${DEBUG_PACKAGE_NAME}
    else
        cd ..
    fi
    print_line
done

#print ANDROID_TEST_PACKAGES
#ANDROID_TEST_PACKAGES=`get_test_packages_for_apks ${ANDROID_TEST_APK_FOLDER_NAMES}`
#print_elements ${ANDROID_TEST_PACKAGES}

#print DEBUG_APK_LIST
#DEBUG_APK_LIST=`get_debug_apks ${ANDROID_TEST_APK_FOLDER_NAMES}`
#print_elements ${DEBUG_APK_LIST}



#print DEBUG_APK_LIST
#DEBUG_APK_LIST=`get_apk_list "debug" | grep -v sample-common | grep -v sample-dagger`
#print_elements ${DEBUG_APK_LIST}

#print_elements `get_apk_folder_names ${DEBUG_APK_LIST}`


#print ANDROID_MANIFEST_FOLDER_NAMES
#ANDROID_MANIFEST_FOLDER_NAMES=`get_manifests_folders_names`
#print_elements ${ANDROID_MANIFEST_FOLDER_NAMES}

#adb -s PRO75SSOCQQ8SCAE shell am instrument -w -r -e debug false \
#\ "ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner"

#adb -s emulator-5554 shell am instrument -w -r -e debug false \
#\ -e class 'ru.surfstudio.android.custom_scope_sample.AnotherScopeSampleAndroidTest' \
#\ ru.surfstudio.android.custom_scope_sample.test/androidx.test.runner.AndroidJUnitRunner