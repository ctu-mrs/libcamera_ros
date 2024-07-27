#ifndef LIBCAMERA_ROS_H
#define LIBCAMERA_ROS_H

#include <libcamera/libcamera.h>

namespace libcamera_ros
{

class LibcameraRos {

public:
  LibcameraRos();

private:
};

// !! we need to instantitate the LibcameraRos class to make it link to other code when included
libcamera_ros::LibcameraRos libcamera_ros_wrapper;

}  // namespace libcamera_ros

#endif  // LIBCAMERA_ROS_H
