FROM debian:10

RUN apt-get update && \
    apt-get install -y unzip build-essential libsnmp-dev p7zip-full golang curl git
COPY mibs/ /mibs/
