FROM openjdk:8-jdk
MAINTAINER Suparit Krityakien <suparit@wongnai.com>

USER root

# Jenkins Swarm Version
ARG SWARM_VERSION=2.2
# Container User
ARG CONTAINER_USER=swarmslave
ARG CONTAINER_UID=1000
ARG CONTAINER_GROUP=swarmslave
ARG CONTAINER_GID=1000

ARG GIT_LFS_VERSION=1.4.1
ARG GIT_LFS_SHA=f02e5f720aad2738458426545d3b9626e7c7410d
ARG TINI_VERSION=0.10.0
ARG TINI_SHA=7d00da20acc5c3eb21d959733917f6672b57dabb
ARG SWARM_SHA=731ca367119d4b46421c70367111f4c9902a2cb7
 
ARG DOCKER_TAR_NAME=docker-1.12.1.tgz

ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Bangkok

# Container Internal Environment Variables
ENV SWARM_HOME=/opt/jenkins-swarm \
    SWARM_WORKDIR=/opt/jenkins
  
RUN /usr/sbin/groupadd --gid $CONTAINER_GID $CONTAINER_GROUP && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --shell /bin/bash $CONTAINER_USER

# Install Development Tools
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt-get update -y && \
    apt-get install -y \
        wget \
        tar \
        gzip \
        bzip2 \
        git \
        python-pip \
        sudo \    
        vim \
        xvfb \
        imagemagick \
        x11vnc \
        google-chrome-stable \
        fonts-thai-tlwg && \
    pip install virtualenv && \
    rm -rf /var/lib/apt/lists/*

# Install Git-LFS
RUN wget -O /tmp/git-lfs-linux-amd64.tar.gz https://github.com/github/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-${GIT_LFS_VERSION}.tar.gz && \
    sha1sum /tmp/git-lfs-linux-amd64.tar.gz && \
    echo "$GIT_LFS_SHA /tmp/git-lfs-linux-amd64.tar.gz" | sha1sum -c - && \
    tar xfv /tmp/git-lfs-linux-amd64.tar.gz -C /tmp && \
    cd /tmp/git-lfs-${GIT_LFS_VERSION}/ && bash -c "/tmp/git-lfs-${GIT_LFS_VERSION}/install.sh" && \
    git lfs install && \
    rm -rf /tmp/*

# Install Tini Zombie Reaper And Signal Forwarder
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini && \
    chmod +x /bin/tini && \
    sha1sum /bin/tini && \
    echo "$TINI_SHA /bin/tini" | sha1sum -c -

# Install Jenkins Swarm-Slave
RUN mkdir -p ${SWARM_HOME} && \
    wget --directory-prefix=${SWARM_HOME} \
      https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_VERSION}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar && \
    sha1sum ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar && \
    echo "$SWARM_SHA ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar" | sha1sum -c - && \
    mv ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar ${SWARM_HOME}/swarm-client-jar-with-dependencies.jar && \
    mkdir -p ${SWARM_WORKDIR} && \
    chown -R ${CONTAINER_USER}:${CONTAINER_GROUP} ${SWARM_HOME} ${SWARM_WORKDIR} && \
    chmod +x ${SWARM_HOME}/swarm-client-jar-with-dependencies.jar

# Install docker client 
RUN wget -O /tmp/docker.tgz https://get.docker.com/builds/Linux/x86_64/${DOCKER_TAR_NAME} && \
    tar zxf /tmp/docker.tgz -C /tmp && \
    cp /tmp/docker/docker /usr/bin/docker  && \
    rm -rf /tmp/*

# Install kubectl 
RUN wget -O /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/bin/kubectl

# Install gosu
RUN wget -O /usr/bin/gosu https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }') && \
    chmod +x /usr/bin/gosu

# Entrypoint Environment Variables
ENV SWARM_VM_PARAMETERS= \
    SWARM_MASTER_URL= \
    SWARM_VM_PARAMETERS= \
    SWARM_JENKINS_USER= \
    SWARM_JENKINS_PASSWORD= \
    SWARM_CLIENT_EXECUTORS= \
    SWARM_CLIENT_LABELS= \
    SWARM_CLIENT_NAME= \
    DISPLAY=:99 \
    XVFB_WHD=1440x900x16 

ADD startXvfb.sh /usr/bin/startXvfb.sh
ADD startx11vnc.sh /usr/bin/startx11vnc.sh

RUN chmod +x /usr/bin/startXvfb.sh /usr/bin/startx11vnc.sh

RUN mkdir /home/${CONTAINER_USER} \
    && chown -R ${CONTAINER_USER}:${CONTAINER_GROUP} /home/${CONTAINER_USER}

EXPOSE 5900

#USER ${CONTAINER_USER}
WORKDIR $SWARM_WORKDIR
VOLUME $SWARM_WORKDIR
ADD docker-entrypoint.sh ${SWARM_HOME}/docker-entrypoint.sh
ENTRYPOINT ["gosu","swarmslave","/bin/tini","--","/opt/jenkins-swarm/docker-entrypoint.sh"]
CMD ["swarm"]
     
