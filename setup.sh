#!/bin/bash
set -e

: '
    Script for quick setup of your environment for using androidTest.sh
'

# create sample avd-config

# export environment variables
# (or add this to ~/.bashrc or ~/.zshrc)

export ANDROID_HOME=~/Android/Sdk # replace to your path of android-sdk
export EMULATOR_HOME=${ANDROID_HOME}/emulator
export EMULATOR_TOOLS_HOME=${ANDROID_HOME}/tools
export AVDMANAGER_HOME=${EMULATOR_TOOLS_HOME}/bin
export PATH=$PATH:${ANDROID_HOME}:${EMULATOR_HOME}:${EMULATOR_TOOLS_HOME}:${AVDMANAGER_HOME}

sudo apt install aapt android-tools-adb xterm -y
