#!/bin/bash
set -e

SHELL_SCRIPTS_DIR=`pwd`
cd ..

./gradlew clean assembleDebug

./${SHELL_SCRIPTS_DIR}/androidTest.sh
