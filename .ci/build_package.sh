#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

VARIANT=$1
ARTIFACTS_FOLDER=$2

sudo apt-get -y update

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" != "arm64" ]]; then
  $MY_PATH/../.ci_scripts/package_build/add_ros_ppa.sh
fi

# dependencies need for build the deb package
sudo apt-get -y install ros-noetic-catkin python3-catkin-tools
sudo apt-get -y install fakeroot dpkg-dev debhelper
sudo pip3 install -U bloom future

sudo apt-get -y install python-is-python3

## | ------------- install libcamera dependencies ------------- |

# without this, the lxml package won't be installed from the internal python dependencies
sudo apt-get -y install libxslt1-dev

rosdep install -y -v --rosdistro=noetic --from-paths ./

# libcamera dependency
sudo apt-get -y install python3-yaml python3-ply python3-jinja2 openssl libudev-dev libssl-dev

pip3 install meson ninja
pip3 install --upgrade meson

## | --------------- install bloom dependencies --------------- |

echo "$0: Running bloom on a package in '$PKG_PATH'"

cd $MY_PATH/..

export DEB_BUILD_OPTIONS="parallel=`nproc`"
bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

SHA=$(git rev-parse --short HEAD)

epoch=2
build_flag="$(date +%Y%m%d.%H%M%S)~on.push.build.git.$SHA"

sed -i "s/(/($epoch:/" ./debian/changelog
sed -i "s/)/.${build_flag})/" ./debian/changelog

echo "$0: calling build on '$PKG_PATH'"

fakeroot debian/rules binary

mv ../*.deb $ARTIFACTS_FOLDER/
