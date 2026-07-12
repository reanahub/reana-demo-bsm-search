# Pin the base image digest so rebuilding this analysis environment is reproducible.
FROM ghcr.io/clelange/root:6.38.04-ubuntu24.04@sha256:e2e6e95b610ac79cc6591920c1adc172a36ed04d903226c8f5d7826c6ef96dd4

# Override the base image's OCI metadata so GHCR links this derived image to
# this repository rather than to the repository that built the ROOT image.
LABEL org.opencontainers.image.source="https://github.com/clelange/reana-demo-bsm-search" \
      org.opencontainers.image.description="Analysis environment for the REANA BSM search example" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        python3-venv \
        zip && \
    rm -rf /var/lib/apt/lists/*

# Use a virtual environment while retaining the base image's matching PyROOT,
# PyYAML, and NumPy installations from the system site packages.
RUN python3 -m venv --system-site-packages /opt/reana-venv
ENV PATH="/opt/reana-venv/bin:${PATH}"

# hftools 0.0.6 was written for Python 2. Pin the minimal Python 3 compatibility
# fork to an immutable commit until the workflow no longer needs this package.
RUN python3 -m pip install --no-cache-dir \
    "hftools @ https://github.com/clelange/hftools/archive/bbd0410f7106aa591ae01f11cfbc942b5fcddf85.tar.gz" \
    "brewer2mpl==1.4.1" \
    "click==8.4.2"

RUN python3 -c "import ROOT, hftools.hepdata, yaml; print(ROOT.gROOT.GetVersion())" && \
    command -v hadd && \
    command -v hfquickplot && \
    command -v zip
