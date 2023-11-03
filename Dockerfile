FROM andrejreznik/python-gdal:py3.10.0-gdal3.2.3

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    TINI_VERSION=v0.19.0

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN apt-get update && \
    apt-get install -y \
      build-essential \
      git \
      wget \
      ffmpeg \
      libsm6 \ 
      libxext6 

COPY requirements.txt /conf/
COPY .datacube.conf /conf/datacube.conf

RUN pip install --no-cache-dir --requirement /conf/requirements.txt
RUN pip install --extra-index-url="https://packages.dea.ga.gov.au" \
  odc-ui \
  odc-stac \
  odc-stats \
  odc-algo \
  odc-io \
  odc-cloud[ASYNC] \
  odc-dscache \
  odc-stac[botocore] \
  odc-apps-cloud \
  odc-apps-dc-tools \
  odc-index

RUN git clone https://github.com/Open-EO/openeo-pg-parser-python.git
RUN cd openeo-pg-parser-python && pip install .

RUN git clone https://github.com/kpapap/openeo_odc_driver.git

WORKDIR /

ENTRYPOINT ["/tini", "--"]

WORKDIR /openeo_odc_driver/openeo_odc_driver/

CMD ["gunicorn","-c","gunicorn.conf.py","odc_backend:app"]
