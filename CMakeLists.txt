cmake_minimum_required(VERSION 3.5)
project(libcamera_ros)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# force the linker to link libcamera_source even when it is not needed for the wrapper lib
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-no-as-needed")

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

include(ExternalProject)

set(LIBCAMERA_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/libcamera_install)
set(LIBCAMERA_INSTALL_DIR ${LIBCAMERA_INSTALL_PREFIX}/${CMAKE_INSTALL_PREFIX})
configure_file(make_install_libcamera.sh.in ${CMAKE_BINARY_DIR}/make_install_libcamera.sh)

set(CATKIN_DEPENDENCIES
  cmake_modules
  roscpp
  )

find_package(catkin REQUIRED COMPONENTS
  ${CATKIN_DEPENDENCIES}
  )

set(LIBRARIES
  LibCameraRos_Wrapper
  )

catkin_package(
  INCLUDE_DIRS include
  CATKIN_DEPENDS ${CATKIN_DEPENDENCIES}
  LIBRARIES ${LIBRARIES}
  DEPENDS
  )

include_directories(
  include
  )

ExternalProject_Add(libcamera_source
  GIT_REPOSITORY      https://github.com/ctu-mrs/libcamera.git
  GIT_TAG             v0.2.0+rpt20240418_build_fix
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

add_library(LibCameraRos_Wrapper
  src/libcamera_ros_wrapper.cpp
  )

add_dependencies(LibCameraRos_Wrapper
  ${catkin_EXPORTED_TARGETS}
  ${${PROJECT_NAME}_EXPORTED_TARGETS}
  libcamera_source
  )

target_link_libraries(LibCameraRos_Wrapper
  ${LIBCAMERA_INSTALL_DIR}/lib/libcamera.so
  ${LIBCAMERA_INSTALL_DIR}/lib/libcamera-base.so
  ${LIBCAMERA_INSTALL_DIR}/lib/libpisp.so
  )

## --------------------------------------------------------------
## |                           Install                          |
## --------------------------------------------------------------

install(TARGETS ${LIBRARIES}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION}
  )

install(DIRECTORY include/libcamera_ros/
  DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
  )

install(DIRECTORY include/libcamera/
  DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION}/libcamera
  )

install(
  DIRECTORY ${LIBCAMERA_INSTALL_DIR}/lib/
  DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}/
  FILES_MATCHING PATTERN "*.so*"
  )

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/share/libpisp
  DESTINATION ${CATKIN_GLOBAL_SHARE_DESTINATION}
  )

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/share/libcamera
  DESTINATION ${CATKIN_GLOBAL_SHARE_DESTINATION}
  )

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/libexec
  DESTINATION ${CATKIN_GLOBAL_SHARE_DESTINATION}/..
  )
