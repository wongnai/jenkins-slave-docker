# Image for Running Jenkinslave in Docker Container
The base docker image to run a Jenkins slave used at Wongnai. It's modified version of https://github.com/blacklabelops/jenkins but uses openjdk image as base image instead of centOS. Moreover, development tools for building and testing are installed and ready for using.

## Installed Tools
Here are the list of installed tools:-
* tar - basic file/directory collector
* gzip - basic compression tool
* bzip2 - better compression tool, some tools need this for building from source code
* git - client for most popular source control
* python - for running some other tools written in python
* python-pip - python package manager
* virtual-env - separate python environment
* vim - best text editor for terminal
* xvfb - frame buffer for running GUI in X environment without monitor
* x11vnc - VNC server for X environment, basically used along with xvfb
* imagemagick - image tools for saving what is render in frame buffer
* google-chrome-stable - default web browser for testing web application
* fonts-thai-tlwg - thai fonts
* docker - docker client
* kubectl - kubernetes command-line client
* gosu - sudo written in go for chaning uid (since we need to run jenkins slave using swarmslave user but we want to shell in to the container as root)

## X Virtual Framebuffer and VNC Server
To start the xvfb, just run:-

    /usr/bin/startXvfb.sh
        
After running successfully, any GUI application can run on it.

To see what's happening in the framebuffer, just start the vnc server using:- 

    /usr/bin/startx11vnc.sh 
    
Any VNC viewer (client) should be able to connect to port 5900.

You can change the display number and viewport size by setting thr following environment variables before running the above commands:-
* DISPLAY - Display number. default is 99.
* XVFB_WHD - Viewport size. default to 1440x900x16.


## Connect to Jenkins master
The following environment variables are used by the container's entrypoint to connect to Jenkins master:-

* SWARM_ENV_FILE - specified environment files and set environment before starting the slave. The file must be accessible by the container (mounting or extend this image). This is basically used for putting all below environment variables in to a file without setting environments during running docker.
* SWARM_MASTER_URL - URL of Jenkins master. Default to http://jenkins:8080
* SWARM_JENKINS_USER - Jenkins username
* SWARM_JENKINS_PASSWORD - Jenkins password
* SWARM_CLIENT_PARAMETERS - More Jenkins slave parameters. eg. label 
* SWARM_CLIENT_EXECUTORS - Number of executors this slave has. Default to number of CPU's cores/hyperthreads.
* SWARM_CLIENT_NAME - Slave node name
* SWARM_VM_PARAMETERS - Java VM parameters
* DOCKER_HOST - Docker host
* TZ - Container timezone. Default to Asia/Bangkok

To run with docker:-

    docker run -d --restart=always \
        -p 5900:5900 \
        -e "SWARM_MASTER_URL=https://jenkinswongnai" \
        -e "SWARM_JENKINS_USER=wongnaidevops" \
        -e "SWARM_JENKINS_PASSWORD=2f52394570e54ffd6" \
        -e "SWARM_CLIENT_PARAMETERS=-labels linux -labels java"
        -e "SWARM_VM_PARAMETERS=-Xmx1024m" \
        -e "SWARM_CLIENT_NAME=builder1" \
        -e "DOCKER_HOST=dockerserver:2375" \
        wongnai/jenkins-slave

## swarmslave
swarmslave is the user for running the jenkins swarm client. Therefore, you may need to put some security related things (eg. ssh keys, docker user/password etc) to /home/swarmslave for example /home/swarmslave/.ssh by either volume mounting or just extending the image.
