#!/bin/bash

rm -rf debian
rm -rf .obj*

bloom-generate rosdebian --os-name ubuntu  --os-version focal --ros-distro noetic

epoch=1
build_flag="$(date +%Y%m%d.%H%M%S)~on.push.build"

sed -i "s/(/($epoch:/" ./debian/changelog
sed -i "s/)/.${build_flag})/" ./debian/changelog

fakeroot debian/rules binary
