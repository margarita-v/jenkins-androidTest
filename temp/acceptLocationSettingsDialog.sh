#!/bin/bash

ACCEPT_BUTTON_ATTRIBUTE='resource-id="android:id/button1"'

#adb shell uiautomator dump
#adb shell cat /storage/emulated/legacy/window_dump.xml | xmllint --format - > window_dump.xml
#cat window_dump.xml | grep 'resource-id="android:id/button1"' | rev | cut -d '"' -f2 | rev

get_accept_button_bounds() {
    #cat window_dump.xml | grep 'resource-id="android:id/button1"' | rev | cut -d '"' -f2 | rev
    cat window_dump.xml | awk -F 'resource-id="android:id/button1"' '{ print $2 }' | awk -F 'bounds="' '{ print $2 }' | cut -d '"' -f1
}

get_nth_coord() {
	echo ${COORDS} | cut -d ' ' -f"$1"
}

get_result_coord() {
    echo $(( ($1+$2)/2 ))
}

#adb shell uiautomator dump
#adb shell cat /storage/emulated/legacy/window_dump.xml | xmllint --format - > window_dump.xml

#uiautomator dump
#cat /storage/emulated/legacy/window_dump.xml | xmllint --format - > window_dump.xml

BOUNDS=`get_accept_button_bounds`
echo ${BOUNDS}

COORDS=`echo ${BOUNDS} | tr '[],' ' '`

X_FIRST=`get_nth_coord "1"`
echo ${X_FIRST}

Y_FIRST=`get_nth_coord "2"`
echo ${Y_FIRST}

X_SECOND=`get_nth_coord "3"`
echo ${X_SECOND}

Y_SECOND=`get_nth_coord "4"`
echo ${Y_SECOND}

X_COORD=`get_result_coord ${X_FIRST} ${Y_FIRST}`
Y_COORD=`get_result_coord ${X_SECOND} ${Y_SECOND}`
echo ${X_COORD} ${Y_COORD}

#adb shell input tap ${X_COORD} ${Y_COORD}

#input tap ${X_COORD} ${Y_COORD}
