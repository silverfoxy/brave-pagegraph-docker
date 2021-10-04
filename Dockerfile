FROM debian:buster
LABEL name "Brave pagegraph on Debian"

# Create non-root user
ARG USER=docker
ARG UID=1000
ARG GID=1000
ARG PW=docker

RUN useradd -m ${USER} --uid=${UID} && echo "${USER}:${PW}" | \
      chpasswd

# Install vim
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]

# Install dependencies
RUN apt update &&\
    apt install -y \
        git \
        pkg-config \
        gperf \
        libxcursor1 \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libsqlite3-dev \
        libreadline-dev \
        libffi-dev \
        curl \
        libbz2-dev \
        xvfb \
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        ca-certificates \
        fonts-liberation \
        libappindicator1 \
        libnss3 \
        lsb-release \
        xdg-utils \
        wget \
        libgbm-dev

# Install Python 3.8 required by brave build
WORKDIR /root/
RUN curl -O https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tar.xz
RUN tar -xf Python-3.8.2.tar.xz
WORKDIR /root/Python-3.8.2
RUN ./configure --enable-optimizations
RUN make -j 4
RUN make altinstall

# Install Node 14
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt update &&\
    apt install -y nodejs python python-pip &&\
    pip install requests

# Clone brave page-graph branch and build (May take 40+ minutes)
WORKDIR /home/docker/
RUN git clone -b page-graph https://github.com/silverfoxy/brave-browser
WORKDIR /home/docker/brave-browser
RUN chown -R docker /home/docker/brave-browser
RUN npm install
USER ${UID}:${GID}
RUN npm run init
RUN npm run build -- Static

# Clone and build pagegraph crawl
WORKDIR /home/docker/
RUN git clone https://github.com/silverfoxy/pagegraph-crawl.git
WORKDIR /home/docker/pagegraph-crawl/
RUN npm install

# Prepare virtual display
RUN Xvfb :99 -ac -screen 0 $XVFB_WHD -nolisten tcp &
RUN xvfb=$!

RUN export DISPLAY=:99

USER root
RUN mkdir -p /tmp/.X11-unix

# Mount logs volume
VOLUME ./logs /home/docker/logs
