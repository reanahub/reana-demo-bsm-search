# Start from the ROOT6 base image:
FROM reanahub/reana-env-root6:6.18.04

# Install HFtools and its dependencies:
RUN apt-get -y update && \
    apt-get -y install \
       libyaml-dev \
       python-numpy \
       zip && \
    apt-get autoremove -y && \
    apt-get clean -y
RUN pip install hftools==0.0.6

# Mount our code:
ADD code /code
WORKDIR /code
