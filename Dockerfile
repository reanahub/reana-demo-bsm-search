FROM rootproject/root-ubuntu16
COPY . /code
WORKDIR /code
USER root
RUN apt-get update && apt-get install -y curl zip && \
    curl -s https://bootstrap.pypa.io/get-pip.py |python && \
    pip install hftools
#USER builder
