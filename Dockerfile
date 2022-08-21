#
# Using the Python 3 image
# - https://hub.docker.com/_/python
#
#FROM python:slim 	# can't use :slim, as we want to have curl
FROM python:3.7

# Copy local code to the container image
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

# Install required Python modules
RUN pip install --no-cache-dir -r requirements.txt

# start-up the app, when the container launches
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app

#  #
#  # Using the Ubuntu 18.04 LTS image
#  # - require some pkg installations
#  #
#  FROM ubuntu:18.04
#  #FROM google/cloud-sdk 	# https://hub.docker.com/r/google/cloud-sdk
#  
#  # install/update Python 3
#  RUN apt-get update && apt-get install -y python3 python3-pip
#  
#  # Copy local code to the container image.
#  ENV APP_HOME /app
#  WORKDIR $APP_HOME
#  COPY . ./
#  
#  # Install Python 3 dependencies.
#  # -includes `Flask'
#  # -includes `gunicorn'
#  RUN pip3 install Flask gunicorn
#  
#  # Run the web service on container startup
#  CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app

# EOF

