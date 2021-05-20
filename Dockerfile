FROM mongo:4.2-bionic
LABEL maintainer="KnowledgeVis, LLC <curtislisle@knowledgevis.com>"

# Dockerfile to build Arbor-Nova self-contained container.  Start with a basic girder instance
# by using startup sequence from Kitware

# expose port for girder
EXPOSE 8080

RUN mkdir /girder

RUN apt-get update && apt-get install -qy \
	apt-utils \
    gcc \
    libpython3-dev \
    git \
    libldap2-dev \
    libsasl2-dev  && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# get wget, used for nodeJS
RUN apt-get update
RUN apt-get install -y wget 

# get python3
RUN apt-get install -y python3
RUN apt-get update
#RUN apt-get install -y distutils
RUN apt-get install -y python3-pip

RUN alias python="python3"
RUN alias pip="pip3"

# get pip3 for installations
#RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py


# install systemd (contains systemctl needed for mongo install)
#RUN apt-get install -y systemd

# install mongoDB
# set the timezone so mongodb can install 
#ENV TZ=Europe/Kiev
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get install -qy curl
#RUN curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc |  apt-key add -
#RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

#RUN apt-get update
#RUN apt-get install -y mongodb-org

# download girder source code
RUN git clone https://github.com/girder/girder.git  /girder

WORKDIR /girder

# See http://click.pocoo.org/5/python3/#python-3-surrogate-handling for more detail on
# why this is necessary.
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# download nodejs for web UI
# install this before girder because girder build step requires npm
RUN curl  -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt-get install -qy nodejs

# added this to eliminate later build problems on 5/20/21
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade cryptography

# TODO: Do we want to create editable installs of plugins as well?  We
# will need a plugin only requirements file for this.
RUN pip3 install --upgrade --upgrade-strategy eager --editable .
RUN pip3 install girder-worker[girder]
RUN girder build


# go to the configuration directory and change the defaults so the website will be visible outside the container
WORKDIR /girder/girder/conf
RUN sed -i -r "s/127.0.0.1/0.0.0.0/" girder.dist.cfg

#----- after girder install
# download girder worker
RUN echo 'installing girder_worker'
WORKDIR /
RUN git clone http://github.com/girder/girder_worker /girder_worker
WORKDIR /girder_worker
#RUN git fetch --all --tags --prune
RUN git checkout 7a590f6f67230e2f98e8acecd313f00d76bdbf00
RUN pip3 install -e .[girder_io]

# get rabbitmq
RUN apt-get update
RUN apt-get install -qy --fix-missing rabbitmq-server

RUN pip3 install .[girder_io,worker]

# added 5/20/21 for r to load
RUN apt-get install -qy libthai-data
RUN apt-get install -qy libhttp-message-perl
RUN apt-get install -qy libarchive-cpio-perl
RUN apt-get install -qy libhtml-form-perl
RUN apt-get install -qy libreadline-dev

# --- install R since it is used by arbor_nova
RUN apt-get install -qy r-base
RUN apt-get install -qy r-base-core

# ----- get arbor_nova
RUN echo 'installing arbor_nova plugin'
#RUN pip install ansible
WORKDIR /
RUN git clone http://github.com/arborworkflows/arbor_nova
WORKDIR /arbor_nova
RUN git checkout terra

# override the default girder webpage
WORKDIR /arbor_nova/girder_plugin
RUN pip3 install -e .

# install the girder_worker jobs
WORKDIR /arbor_nova/girder_worker_tasks
RUN pip3 install -e .

# --- install the UI
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update &&  apt-get install -qy yarn
WORKDIR /arbor_nova/client
RUN yarn global add @vue/cli
RUN yarn install
RUN yarn build
# gave up on this build time copy because we couldn't reference the dist dir.  the copy has been moved to startup.sh
#COPY ./dist /arbornova

# -- install dependencies for Terra display
RUN pip3 install pandas
RUN pip3 install scikit-learn
RUN pip3 install girder_client

# install nginx to run trelliscope
#EXPOSE 80
#RUN apt-get install -qy nginx

WORKDIR /
# copy init script(s) over and start all jobs
COPY . .

ENTRYPOINT ["sh", "startup.sh"]

