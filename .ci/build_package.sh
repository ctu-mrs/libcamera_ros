#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

VARIANT=$1
ARTIFACTS_FOLDER=$2

echo "$0: installing ros dependencies"

rosdep install -y -v --rosdistro=noetic --from-paths ./

echo "$0: installing additional apt dependencies"

# libcamera dependency
sudo apt-get -y install python3-yaml python3-ply python3-jinja2 openssl libudev-dev libssl-dev

echo "$0: installing meson and ninja"

pip3 install meson ninja
pip3 install --upgrade meson

## | --------------- install bloom dependencies --------------- |

echo "$0: Running bloom on a package in '$PKG_PATH'"

cd $MY_PATH/..

bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

SHA=$(git rev-parse --short HEAD)

epoch=2
build_flag="$(date +%Y%m%d.%H%M%S)~on.push.build.git.$SHA"

sed -i "s/(/($epoch:/" ./debian/changelog
sed -i "s/)/.${build_flag})/" ./debian/changelog

echo "$0: calling build on '$PKG_PATH'"

fakeroot debian/rules binary

mv ../*.deb $ARTIFACTS_FOLDER/
