#!/bin/sh

DISPLAY=${DISPLAY:-:99}

XVFB_PID=$(ps -ef | grep Xvfb | grep -v grep | grep -v startXvfb.sh | grep ${DISPLAY} | awk '{print $2}')

if [ -z "${XVFB_PID}" ]; then
    echo "Starting framebuffer at ${DISPLAY}"
    Xvfb ${DISPLAY} -ac -screen 0 ${XVFB_WHD:-1440x900x16} -nolisten tcp &
else
    echo "Framebuffer (pid = ${XVFB_PID}) is already running."
fi
