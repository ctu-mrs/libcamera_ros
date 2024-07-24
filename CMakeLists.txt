cmake_minimum_required(VERSION 3.5)
project(libcamera)

find_package(catkin REQUIRED)
catkin_package(
  CATKIN_DEPENDS ${CATKIN_DEPENDENCIES}
  )

# set default build type
# https://blog.kitware.com/cmake-and-the-default-build-type/
if((NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES) OR (CMAKE_BUILD_TYPE STREQUAL "None"))
  set(default_build_type "Release")
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
      STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()

string(TOLOWER ${CMAKE_BUILD_TYPE} MESON_BUILD_TYPE)

if ((MESON_BUILD_TYPE STREQUAL "relwithdebinfo"))
  set(MESON_BUILD_TYPE "debugoptimized")
endif()

if(NOT NJOBS)
  set(NJOBS 0)
endif()

find_package(OpenSSL REQUIRED)

include(ExternalProject)

set(LIBCAMERA_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/libcamera_install)
set(LIBCAMERA_INSTALL_DIR ${LIBCAMERA_INSTALL_PREFIX}/${CMAKE_INSTALL_PREFIX})
configure_file(make_install_libcamera.sh.in ${CMAKE_BINARY_DIR}/make_install_libcamera.sh)

catkin_package(
    DEPENDS
    CATKIN_DEPENDS
    LIBRARIES libcamera
)

ExternalProject_Add(libcamera_source
  GIT_REPOSITORY      https://github.com/ctu-mrs/libcamera.git
  GIT_TAG             v0.3.0+rpt20240617_build_fix
  GIT_SHALLOW         ON
  CONFIGURE_COMMAND   meson setup build ../libcamera_source --prefix ${CMAKE_INSTALL_PREFIX} --libdir lib --buildtype ${MESON_BUILD_TYPE} --auto-features=disabled
                        -Dpipelines=rpi/pisp
                        -Dipas=rpi/pisp
                        -Dv4l2=false
                        -Dgstreamer=disabled
                        -Dtest=false
                        -Dlc-compliance=disabled
                        -Dcam=disabled
                        -Dqcam=disabled
                        -Ddocumentation=disabled
  BUILD_COMMAND       meson compile -C build --jobs ${NJOBS}
  INSTALL_COMMAND ${CMAKE_BINARY_DIR}/make_install_libcamera.sh
)

add_library(libcamera src/wrap_lib.cc)

target_link_libraries(libcamera -Wl,--whole-archive -Wl,--no-whole-archive)

add_dependencies(libcamera libcamera_source)

## --------------------------------------------------------------
## |                           Install                          |
## --------------------------------------------------------------

install(TARGETS libcamera
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/include/libcamera/libcamera/
  DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
  )
