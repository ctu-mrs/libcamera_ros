# libcamera colcon wrapper

This implements a thin colcon wrapper around the [libcamera](https://libcamera.org) meson project. It only builds the main library without examples, tests or documentation.

To be able to build this package you will need the follow packages

```bash
apt install colcon meson python3-bloom python3-ply debhelper
```
