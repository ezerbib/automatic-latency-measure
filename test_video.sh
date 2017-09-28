sudo chmod 666 /dev/video0
DISPLAY=:0 gst-launch -v v4l2src   ! xvimagesink
