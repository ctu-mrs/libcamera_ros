cmake_minimum_required(VERSION 3.20.0)
project(libcamera_ros)

# set the correct standards
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set the compile options to show code warnings
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra)
endif()

if(ENABLE_COVERAGE)
  message(WARNING "building for coverage, the performance might be limited")

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage -fprofile-arcs")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -fprofile-arcs")

  add_definitions("-O1")
  add_definitions("-g")
endif()

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

find_package(ament_cmake REQUIRED)

ExternalProject_Add(libcamera_source
  GIT_REPOSITORY      https://github.com/raspberrypi/libcamera.git
  GIT_TAG             v0.7.0+rpt20260205
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

add_library(libcamera_ros INTERFACE)
add_library(libcamera_ros::libcamera_ros ALIAS libcamera_ros)

set_target_properties(libcamera_ros
  PROPERTIES
    EXPORT_NAME libcamera_ros
    OUTPUT_NAME libcamera_ros
)

target_include_directories(libcamera_ros
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(libcamera_ros
  INTERFACE
    $<BUILD_INTERFACE:${LIBCAMERA_INSTALL_DIR}/lib/libcamera.so>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/lib/libcamera.so>
    $<BUILD_INTERFACE:${LIBCAMERA_INSTALL_DIR}/lib/libcamera-base.so>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/lib/libcamera-base.so>
    $<BUILD_INTERFACE:${LIBCAMERA_INSTALL_DIR}/lib/libpisp.so>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/lib/libpisp.so>
)

## --------------------------------------------------------------
## |                           Install                          |
## --------------------------------------------------------------

install(TARGETS libcamera_ros EXPORT export_${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/include/libcamera/libcamera
  DESTINATION include
)

install(
  DIRECTORY ${LIBCAMERA_INSTALL_DIR}/lib/
  DESTINATION lib/
  FILES_MATCHING PATTERN "*.so*"
)

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/share/libpisp
  DESTINATION share
)

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/share/libcamera
  DESTINATION share
)

install(DIRECTORY ${LIBCAMERA_INSTALL_DIR}/libexec
  USE_SOURCE_PERMISSIONS
  DESTINATION share/..
)

ament_export_libraries(
  ${LIBRARIES}
)

ament_export_targets(
  export_${PROJECT_NAME} HAS_LIBRARY_TARGET
)

ament_package()
