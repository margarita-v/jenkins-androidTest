#!/bin/bash

get_accept_button_bounds() {
	xmllint window_dump.xml | grep 'resource-id="android:id/button1"' | grep bounds= | cut -d '"' -f2
}

get_coord() {
	echo $COORDS | cut -d ' ' -f"$1"
}

BOUNDS=`get_accept_button_bounds`
echo $BOUNDS

COORDS=`echo $BOUNDS | tr '[],' ' '`

X_FIRST=`get_coord "1"`
echo $X_FIRST

Y_FIRST=`get_coord "2"`
echo $Y_FIRST

X_SECOND=`get_coord "3"`
echo $X_SECOND

Y_SECOND=`get_coord "4"`
echo $Y_SECOND

X_COORD=$(( ($X_FIRST+$Y_FIRST)/2 ))
Y_COORD=$(( ($X_SECOND+$Y_SECOND)/2 ))
echo $X_COORD $Y_COORD

input tap $X_COORD $Y_COORD
