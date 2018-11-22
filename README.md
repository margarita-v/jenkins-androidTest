# jenkins-androidTest
Scripts which allow launching android instrumental tests on CI.

You can assemble and launch android instrumental tests for your project on custom emulator
on your local machine, and also you can easily use this scripts for CI.

Parameters of your custom emulator must be in avd-config file.

setup.sh contains setup instructions for using this scripts.

## Usage
1. In your android project create folder which will contain this scripts (for example, ci-shell-scripts folder)
and move these scripts to this folder.
1. Create sample avd-config in folder with scripts.
1. If you want to assemble and run all APKs with one command, run:
```
    chmod 755 run.sh
    ./run.sh
```
Or, if your debug APKs have been assembled on previous stage, run:
```
    chmod 755 androidTest.sh
    ./androidTest.sh
```