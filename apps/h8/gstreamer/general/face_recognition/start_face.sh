#!/bin/bash
export ROS_DOMAIN_ID=20
export HAILO_MONITOR=1
source /opt/ros/jazzy/setup.bash
source /home/pi/colcon_ws/install/setup.bash
source /home/pi/tappas/scripts/misc/checks_before_run.sh

export GSCAM_CONFIG="gst-launch-1.0 libcamerasrc ! video/x-raw,format=YUY2,width=1024,height=576,framerate=15/1 ! \
queue max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
queue name=hailo_pre_convert_0 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! videoconvert n-threads=4 qos=false ! \
queue name=pre_detector_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
tee name=t hailomuxer name=hmux t. ! queue name=detector_bypass_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hmux. t. ! videoscale name=face_videoscale method=0 n-threads=4 add-borders=false qos=false ! video/x-raw, pixel-aspect-ratio=1/1 ! \
queue leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailonet hef-path=/home/pi/tappas/apps/h8/gstreamer/general/detection/resources/yolov8m.hef batch-size=1 nms-score-threshold=0.3 nms-iou-threshold=0.45 output-format-type=HAILO_FORMAT_TYPE_FLOAT32 scheduling-algorithm=1 vdevice-key=1 ! \
queue leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailofilter function-name=yolov8m so-path=/home/pi/tappas/apps/h8/gstreamer/libs/post_processes//libyolo_hailortpp_post.so config-path=null qos=false ! \
queue name=pre_face_detector_infer_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailonet hef-path=/home/pi/tappas/apps/h8/gstreamer/general/face_recognition/resources/scrfd_10g.hef scheduling-algorithm=1 vdevice-key=1 ! \
queue name=detector_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailofilter so-path=/home/pi/tappas/apps/h8/gstreamer/libs/post_processes//libscrfd_post.so name=face_detection_hailofilter qos=false config-path=/home/pi/tappas/apps/h8/gstreamer/general/face_recognition/resources/configs/scrfd.json function_name=scrfd_10g ! \
queue leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! hmux. hmux. ! queue name=pre_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailotracker name=hailo_face_tracker class-id=-1 kalman-dist-thr=0.7 iou-thr=0.8 init-iou-thr=0.9 keep-new-frames=2 keep-tracked-frames=6 keep-lost-frames=8 keep-past-metadata=true qos=false ! \
queue name=hailo_post_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailocropper so-path=/home/pi/tappas/apps/h8/gstreamer/libs/post_processes//cropping_algorithms/libvms_croppers.so function-name=face_recognition internal-offset=true name=cropper2 hailoaggregator name=agg2 cropper2. ! \
queue name=bypess2_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! agg2. cropper2. ! \
queue name=pre_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailofilter so-path=/home/pi/tappas/apps/h8/gstreamer/libs/apps/vms//libvms_face_align.so name=face_align_hailofilter use-gst-buffer=true qos=false ! \
queue name=detector_pos_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailonet hef-path=/home/pi/tappas/apps/h8/gstreamer/general/face_recognition/resources/arcface_mobilefacenet_v1.hef scheduling-algorithm=1 vdevice-key=1 ! \
queue name=recognition_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailofilter function-name=arcface_rgb so-path=/home/pi/tappas/apps/h8/gstreamer/libs/post_processes//libface_recognition_post.so name=face_recognition_hailofilter qos=false ! \
queue name=recognition_pre_agg_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! agg2. agg2. ! \
queue name=hailo_pre_gallery_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailogallery gallery-file-path=/home/pi/tappas/apps/h8/gstreamer/general/face_recognition/resources/gallery/face_recognition_local_gallery_rgba.json load-local-gallery=true similarity-thr=.4 gallery-queue-size=20 class-id=-1 ! \
queue name=hailo_pre_draw2 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
hailooverlay name=hailo_overlay qos=false show-confidence=false local-gallery=true line-thickness=5 font-thickness=2 landmark-point-radius=8 ! \
queue name=hailo_post_draw leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
videoconvert n-threads=4 qos=false name=display_videoconvert qos=false ! \
queue name=hailo_display_q_0 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
jpegenc "

ros2 run gscam2 gscam_main --ros-args -p image_encoding:=jpeg --remap /image_raw:=/camera/image_raw \
--remap /image_raw/compressed:=/camera/image_raw/compressed --remap /camera_info:=/camera/camera_info

