#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

VARIANT=$1
ARTIFACTS_FOLDER=$2

PACKAGE_PATH=/tmp/package_copy
mkdir -p $PACKAGE_PATH

cp -r $MY_PATH/.. $PACKAGE_PATH/

## | ------------- detect current CPU architectur ------------- |

CPU_ARCH=$(uname -m)
if [[ "$CPU_ARCH" == "x86_64" ]]; then
  echo "$0: detected amd64 architecture"
  ARCH="amd64"
else
  echo "$0: amd64 architecture not detected, assuming arm64"
  ARCH="arm64"
fi

## | ----------------------- Install ROS ---------------------- |

$PACKAGE_PATH/.ci_scripts/package_build/add_ros_ppa.sh

## | ----------------------- add MRS PPA ---------------------- |

curl https://ctu-mrs.github.io/ppa-${VARIANT}/add_ppa.sh | bash

## | ------------------ install dependencies ------------------ |

# without this, the lxml package won't be installed from the internal python dependencies
sudo apt-get -y install libxslt1-dev

rosdep install -y -v --rosdistro=noetic --from-paths ./

sudo apt-get -y install ros-noetic-catkin python3-catkin-tools

# libcamera dependency
sudo apt-get -y install python3-yaml python3-ply python3-jinja2 openssl libudev-dev libssl-dev
pip3 install --user meson
pip3 install --upgrade meson

## | ---------------- prepare catkin workspace ---------------- |

WORKSPACE_PATH=/tmp/workspace

mkdir -p $WORKSPACE_PATH/src
cd $WORKSPACE_PATH/

source /opt/ros/noetic/setup.bash

catkin init
catkin config --profile release --cmake-args -DCMAKE_BUILD_TYPE=Release
catkin config --profile relWithDebInfo --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo
catkin profile set relWithDebugInfo
catkin config --install

ln -sf $PACKAGE_PATH $WORKSPACE_PATH/src/libcamera

## | ------------------------ build libcamera ----------------------- |

cd $WORKSPACE_PATH
catkin build --limit-status-rate 0.2 --summarize --verbose

## | -------- extract build artefacts into deb package -------- |

TMP_PATH=/tmp/libcamera

mkdir -p $TMP_PATH/package/DEBIAN
mkdir -p $TMP_PATH/package/opt/ros/noetic/share

# cp -r $WORKSPACE_PATH/install/bin/cam $TMP_PATH/package/opt/ros/noetic/lib/libcamera/.
cp -r $WORKSPACE_PATH/install/include/libcamera $TMP_PATH/package/opt/ros/noetic/include
cp -r $WORKSPACE_PATH/install/share/libcamera $TMP_PATH/package/opt/ros/noetic/share
cp -r $WORKSPACE_PATH/install/libexec $TMP_PATH/package/opt/ros/noetic/libexec
cp -r $WORKSPACE_PATH/install/lib $TMP_PATH/package/opt/ros/noetic/lib
rm $TMP_PATH/package/opt/ros/noetic/lib/pkgconfig/catkin_tools_prebuild.pc
cp -r $PACKAGE_PATH/.ci/libcameraConfig.cmake $TMP_PATH/package/opt/ros/noetic/share/libcamera/cmake/libcameraConfig.cmake

# extract package version
VERSION=$(cat $PACKAGE_PATH/package.xml | grep '<version>' | sed -e 's/\s*<\/*version>//g')
echo "$0: Detected version $VERSION"

echo "Package: ros-noetic-libcamera
Version: $VERSION
Architecture: $ARCH
Maintainer: Tomas Baca <tomas.baca@fel.cvut.cz>
Description: libcamera" > $TMP_PATH/package/DEBIAN/control

cd $TMP_PATH

sudo apt-get -y install dpkg-dev

dpkg-deb --build --root-owner-group package
dpkg-name package.deb

mv *.deb $ARTIFACTS_FOLDER/
