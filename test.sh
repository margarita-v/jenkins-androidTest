#!/bin/bash

#EMULATOR_STATUS=`adb devices | grep emulator | cut -f1 | xargs -I{} adb -s {} shell getprop init.svc.bootanim`
EMULATOR_STATUS=`adb devices | grep emulator | cut -f1`
if [[ -z "$EMULATOR_STATUS" ]]; then
        echo 1
    else
        echo 0
fi