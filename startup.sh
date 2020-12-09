#!/bin/sh

# copy files over because we couldn't copy during the docker build process 
cp -r /arbor_nova/client/dist /usr/share/girder/static/arbornova

# copy terra data for access.  Eventually change this to content stored in girder and uploaded 
# by girder jobs
cp /arbor_nova/girder_worker_tasks/data/*.csv /

# run mongo
#nohup  mongod --config /etc/mongod.conf &
nohup  mongod  &
girder serve &

# the communication between jobs and girder
rabbitmq-server &

# wait for girder to come up and then create an assetstore
sleep 10
python3 girder_assetstore.py


# removed because trelliscope isn't completely integrated and needs a large datafile directory

# copy the trelliscope data sover to the webroot
#cp /trelliscope_data/output*zip /var/www
#unzip /var/www/output*zip -d /var/www
#rm -r /var/www/html
#mv /var/www/output /var/www/html
# start nginx
#nginx

# force girder worker to run as root because we don't have other users
export C_FORCE_ROOT=True
/usr/bin/python3 -m girder_worker

