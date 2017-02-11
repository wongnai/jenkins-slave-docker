#!/bin/sh

DISPLAY=${DISPLAY:-:99}

X11VNC_PID=$(ps -ef | grep x11vnc | grep -v grep | grep -v startx11vnc.sh | grep ${DISPLAY} | awk '{print $2}')

if [ -z "${X11VNC_PID}" ]; then
    echo "Starting X11 VNC server at ${DISPLAY}"
    x11vnc -display ${DISPLAY} -nopw &
else
    echo "X11 VNC server (pid = ${X11VNC_PID}) is already running."
fi
