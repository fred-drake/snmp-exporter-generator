FROM debian:10

ARG GENERATOR_DIR=/root/go/src/github.com/prometheus/snmp_exporter/generator
RUN apt-get update && \
    apt-get install -y unzip build-essential libsnmp-dev p7zip-full golang curl git
RUN go get github.com/prometheus/snmp_exporter/generator && \
    cd ${GENERATOR_DIR} && \
    go build && \
    make mibs
COPY mibs/ /mibs/
COPY generator.yml ${GENERATOR_DIR}/generator.yml

RUN cd ${GENERATOR_DIR}; export MIBDIRS=mibs ./generator generate -o /opt/snmp.yml