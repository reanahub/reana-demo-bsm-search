# Start from the ROOT6 base image:
FROM reanahub/reana-env-root6

# Install HFtools:
RUN apt-get -y update && \
    apt-get -y install \
       python-pip \
       zip && \
    apt-get autoremove -y && \
    apt-get clean -y
RUN pip install hftools

# Mount our code:
ADD code /code
WORKDIR /code
